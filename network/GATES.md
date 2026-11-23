# Network

Mở khi thêm cuộc gọi ra ngoài, đổi timeout, retry, TLS, pool kết nối, rate limit, health check, hoặc đường từ client lên server. File này là luật trên dây. Luật nghiệp vụ của endpoint nằm ở Backend.

Nguồn tinh chỉnh: mục resilience và idempotency trong [paranoid-qa backend](https://github.com/akovalion/paranoid-qa/blob/main/skills/testing/references/backend.md), cổng production về timeout và khuếch đại retry.

## G1 — Hạn và thử lại

BLOCK

- [ ] Mọi cuộc gọi ra (HTTP, DB, cache, DNS nếu tự phân giải, hàng đợi) có timeout kết nối và timeout toàn phần. Không có cuộc gọi chờ vô hạn.
- [ ] Deadline của request người dùng lớn hơn tổng timeout các bước tuần tự bên trong, và nhỏ hơn timeout của proxy phía trước. Ghi ba số đó trong design note khi đường có từ hai hop.
- [ ] Retry chỉ áp vào lỗi tạm thời (timeout, reset, 429, 503) trên thao tác idempotent. POST tạo mới không có khóa idempotency thì không retry.
- [ ] Retry có số lần tối đa, backoff, và jitter. Nhiều lớp (client, SDK, gateway, worker) không retry chồng lên nhau. Một lớp được chỉ định là chủ retry.
- [ ] 429 trả `Retry-After` hoặc equivalent. Client tôn trọng khoảng đó.
- [ ] Fan-out có trần đồng thời từng dependency. Chậm của một dependency không được mở vô hạn request.

DECIDE

- [ ] Khi dependency chết: trả lỗi, phục vụ dữ liệu cũ, hay xếp hàng. Một lựa chọn, ghi người dùng thấy gì.
- [ ] Circuit breaker hoặc shedding chỉ thêm khi đã đo được lỗi lặp. Ngưỡng mở mạch nằm trong note.

## G1 — Vận chuyển và biên

BLOCK

- [ ] Traffic production dùng TLS. Chứng chỉ hết hạn có chỗ quan sát.
- [ ] Dữ liệu công cộng và dữ liệu theo user không dùng chung cache key. Key cache gồm tenant và chiều phân quyền khi nội dung khác nhau theo người xem.
- [ ] Pool DB và pool HTTP có trần. Tổng connection mọi process nằm dưới ngân sách server DB.
- [ ] Load balancer, nếu có nhiều instance, gọi health check thật (sẵn sàng phụ thuộc DB khi request cần DB). Instance xấu bị đưa ra khỏi vòng.
- [ ] Định danh request đi qua log của các hop mình sở hữu, để một lỗi timeout truy được từ client tới service.
- [ ] HTTP client đặt timeout tại nơi tạo client, không phụ thuộc default của thư viện.
- [ ] Dependency không trả lời trong hạn thì request kết thúc với lỗi đã định nghĩa. Test hoặc kiểm tra tay ghi hạn đó và lỗi nhận được.

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
