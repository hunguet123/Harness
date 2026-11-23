# Network

Mở khi thêm cuộc gọi ra ngoài, đổi timeout, retry, TLS, pool kết nối, rate limit, health check, hoặc đường từ client lên server. File này là luật trên dây. Luật nghiệp vụ của endpoint nằm ở Backend.

Nguồn tinh chỉnh: mục resilience và idempotency trong [paranoid-qa backend](https://github.com/akovalion/paranoid-qa/blob/main/skills/testing/references/backend.md), cổng production về timeout và khuếch đại retry.

## Bản đồ module đường truyền và ngôn ngữ

Các thành phần giao tiếp mạng tách thành 5 module rõ vai trò:

- `contracts-idl`: đặc tả hợp đồng biên có phiên bản (`OpenAPI`, `Protobuf`/gRPC, `GraphQL`, schema sự kiện/webhook kèm chuẩn chữ ký `HMAC` + mốc thời gian).
- `ingress-edge`: TLS termination, reverse proxy / gateway, CORS, giới hạn kích thước request, rate-limit phía server (`429` + `Retry-After`).
- `egress-client`: HTTP/RPC client dùng chung có pool giới hạn kết nối, cấu hình tường minh `connect timeout` + `read/write timeout` + `total deadline`, chặn SSRF vào dải mạng nội bộ khi gọi URL động.
- `resilience-policy`: truyền `Idempotency-Key`, chỉ định duy nhất một lớp làm chủ retry (kèm backoff + jitter), circuit breaker theo từng dependency, trần đồng thời (`bulkhead`/`semaphore`) khi fan-out.
- `propagation-health`: truyền tín hiệu hủy xuyên hàm (`context.Context` / `AbortSignal` / `CancellationToken`), nối `request-id` / `traceparent` qua các hop, và endpoint health `live`/`ready`.

**Hồ sơ ngôn ngữ & IDL:** mở [SQL & IDL](../languages/sql-idl.md) cho `OpenAPI`/`Protobuf`/`GraphQL`, và mở hồ sơ ngôn ngữ của client/server để khóa đúng cơ chế hủy & pool ([Go](../languages/go.md), [TypeScript](../languages/typescript.md), [Python](../languages/python.md), [Java/Kotlin](../languages/jvm.md), [Rust](../languages/rust.md), [C#](../languages/csharp.md), [Swift/Dart](../languages/mobile-swift-dart.md)).

## G1 — Hạn, thử lại và biên theo từng thay đổi

BLOCK cho mọi thay đổi thêm/sửa cuộc gọi ra, cache theo nội dung, fan-out, hoặc chính sách timeout/retry:

- [ ] Cuộc gọi ra (HTTP, DB, cache, DNS nếu tự phân giải, hàng đợi) có timeout kết nối và timeout toàn phần. Không có cuộc gọi chờ vô hạn.
- [ ] Deadline của request người dùng lớn hơn tổng timeout các bước tuần tự bên trong, và nhỏ hơn timeout của proxy phía trước. Ghi ba số đó trong design note khi đường có từ hai hop.
- [ ] Retry chỉ áp vào lỗi tạm thời (timeout, reset, 408, 429, 502, 503, 504) trên thao tác idempotent. POST tạo mới không có khóa idempotency thì không retry. `401` xử lý ở luồng làm mới phiên (tối đa một lần), không nằm trong vòng retry mạng.
- [ ] Retry có số lần tối đa, backoff, và jitter. Nhiều lớp (client, SDK, gateway, worker) không retry chồng lên nhau. Một lớp được chỉ định là chủ retry.
- [ ] 429 trả `Retry-After` hoặc equivalent. Client tôn trọng khoảng đó.
- [ ] Fan-out có trần đồng thời từng dependency. Chậm của một dependency không được mở vô hạn request.
- [ ] Dữ liệu công cộng và dữ liệu theo user không dùng chung cache key. Key cache gồm tenant và chiều phân quyền khi nội dung khác nhau theo người xem.
- [ ] Cuộc gọi ra lấy URL/host từ input người dùng hoặc webhook được chặn SSRF: chỉ cho phép scheme/domain hợp lệ và từ chối địa chỉ phân giải về loopback, link-local / cloud metadata (`169.254.169.254`), hoặc mạng nội bộ RFC1918/IPv6 (kể cả sau khi redirect).
- [ ] Dependency không trả lời trong hạn thì request kết thúc với lỗi đã định nghĩa. Test hoặc kiểm tra tay ghi hạn đó và lỗi nhận được.

DECIDE

- [ ] Khi dependency chết: trả lỗi, phục vụ dữ liệu cũ, hay xếp hàng. Một lựa chọn, ghi người dùng thấy gì.
- [ ] Circuit breaker hoặc shedding chỉ thêm khi đã đo được lỗi lặp. Ngưỡng mở mạch nằm trong note.

## G1 — Chuẩn nền service và client

BLOCK khi dựng mới service, tạo HTTP/DB client hoặc pool mới, hoặc sửa cấu hình TLS / load balancer / tracing. Task chỉ gọi trên client chuẩn có sẵn thì đánh dấu "trên nền có sẵn" trong brief:

- [ ] Traffic production dùng TLS. Chứng chỉ hết hạn có chỗ quan sát.
- [ ] HTTP client đặt timeout tại nơi khởi tạo client dùng chung, không phụ thuộc default của thư viện và không tạo mới client/pool trên mỗi request.
- [ ] Pool DB và pool HTTP có trần. Tổng connection mọi process nằm dưới ngân sách server DB.
- [ ] Load balancer, nếu có nhiều instance, gọi health check thật (sẵn sàng phụ thuộc DB khi request cần DB). Instance xấu bị đưa ra khỏi vòng.
- [ ] Định danh request đi qua log/header của các hop mình sở hữu, để một lỗi timeout truy được từ client tới service.

## G2 — Việc phải thử

BLOCK khi đường đó có retry hoặc ghi:

- [ ] Timeout rồi gửi lại không tạo hai hiệu ứng (hai đơn, hai trừ tiền, hai mail).
- [ ] Lỗi 4xx nghiệp vụ không bị retry.
- [ ] Đứt kết nối giữa chừng (headers đã gửi, body chưa xong) có hành vi đã định: thất bại sạch hoặc ghi idempotent.

## G3 — Cờ đỏ

- Retry mặc định của SDK trên POST tạo tài nguyên.
- Client timeout ngắn hơn server, server vẫn làm xong rồi client bỏ kết quả và gửi lại.
- Rate limit đếm trong DB trên đường nóng thay vì bộ đếm trong bộ nhớ hoặc Redis.
- Health check luôn 200 khi dependency bắt buộc đã chết, balancer tiếp tục đổ traffic.
- Bí mật trong query string (lọt log và cache).

## Mở thêm

- Khóa idempotency và mã lỗi: [backend/GATES.md](../backend/GATES.md)
- Transaction không ôm cuộc gọi mạng: [database/GATES.md](../database/GATES.md)
- Có cần queue hay cache không: [system-design/GATES.md](../system-design/GATES.md)
- Client di động trên mạng yếu: [mobile/GATES.md](../mobile/GATES.md)
