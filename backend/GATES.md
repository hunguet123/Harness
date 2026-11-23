# Backend

Mở khi đổi API, use case, phân quyền, job, hoặc tích hợp. Cổng này không gắn framework. Lệnh unit, integration, lint, và build là lệnh của project đích, ghi trong change brief.

Nguồn tinh chỉnh: cổng xong của [harness-kit](https://github.com/romabeckman/harness-kit/blob/main/agents/developer-backend.md), bản đồ [backend-things](https://github.com/rendyspratama/backend-things), cặp engineer/reviewer của [harness-claude-code](https://github.com/MartinKChen/harness-claude-code).

## Bản đồ module và ngôn ngữ

Chiều phụ thuộc một chiều bắt buộc (cấm import ngược mũi tên):

```text
bootstrap ──► transport / jobs-outbox ──► application ──► domain
bootstrap ──► persistence / integrations ──────┘ (hiện thực hóa port của application/domain)
```

- `domain`: entity, aggregate, value object, bất biến nghiệp vụ và lỗi miền thuần túy. **Cấm import** framework HTTP/RPC, ORM/SQL driver, SDK hãng ngoài hay biến môi trường.
- `application` (`use-cases`): điều phối luồng nghiệp vụ, kiểm tra phân quyền trên tài nguyên, làm chủ ranh giới transaction, khai báo `port` (interface kho lưu trữ / cổng ngoài).
- `transport` (`http`, `grpc`, `graphql`, `webhook`): xác thực chữ ký/phiên, validate DTO biên, gọi `application`, ánh xạ lỗi miền ra mã trả về ổn định. Không đặt luật nghiệp vụ hay câu SQL tại đây.
- `persistence`: hiện thực hóa repository, truy vấn dữ liệu, mapper giữa bảng kho lưu trữ và `domain`.
- `jobs-outbox`: worker hàng đợi, cron/scheduler, tiến trình đọc `outbox` phát sự kiện và `inbox` dedupe — gọi chung vào `application`, không nhân bản luật nghiệp vụ.
- `integrations`: adapter bọc dịch vụ bên thứ ba (thanh toán, thông báo, lưu trữ), dịch DTO ngoài về kiểu nội bộ (anti-corruption layer).
- `bootstrap` (`cmd` / `main` / `config`): đọc cấu hình môi trường fail-fast, nối DI, khởi tạo pool, health `live`/`ready`, telemetry và đường tắt nhẹ nhàng.

*Dự án mới:* tạo đúng các module có dùng theo sơ đồ trên. *Dự án đã có:* ánh xạ thư mục hiện tại vào các vai trò này trong brief/note và cấm tạo thêm cạnh phụ thuộc ngược chiều.

**Hồ sơ ngôn ngữ Backend (mở kèm file khớp repo):** [TypeScript](../languages/typescript.md) · [Go](../languages/go.md) · [Python](../languages/python.md) · [Java/Kotlin](../languages/jvm.md) · [Rust](../languages/rust.md) · [C#/.NET](../languages/csharp.md) · [SQL & IDL](../languages/sql-idl.md).

## Kiểm chứng

BLOCK khi project đích có lệnh tương ứng. Không có lệnh thì ghi kiểm tra tay trong brief: bước, dữ liệu vào, kết quả.

| Việc | Khi nào |
| --- | --- |
| Unit | Mọi thay đổi logic |
| Integration hoặc end-to-end | Đổi biên HTTP/RPC, phân quyền, hoặc đọc/ghi kho |
| Lint và build | Trước khi coi là xong |

## G1 — Hợp đồng API

BLOCK

- [ ] Mỗi endpoint mới hoặc đổi có method, path, status thành công, status lỗi, và một ví dụ body. **Bằng chứng:** design note hoặc mô tả trong test e2e.
- [ ] Danh sách dùng thứ tự ổn định và phân trang. Offset sâu trên bảng lớn chuyển sang keyset; ghi trong note nếu vẫn dùng offset vì dữ liệu nhỏ.
- [ ] Lỗi có dạng ổn định: mã, thông điệp an toàn với client, không trả stack trace hay câu SQL.
- [ ] Input đi qua validation ở biên (schema hoặc kiểu kiểm được) trước khi vào use case. Field bắt buộc, kiểu, và giới hạn độ dài nằm trong schema đó.
- [ ] Phân quyền chạy trước khi đổi trạng thái. Đọc hoặc ghi theo chủ sở hữu kiểm tra đúng resource của actor đó, không chỉ "đã đăng nhập".
- [ ] Ghi có thể bị client, job, hoặc webhook gửi lại thì có khóa idempotency hoặc ràng buộc unique. Gửi lại trả kết quả lần đầu, không tạo bản thứ hai.
- [ ] Webhook nhận từ bên ngoài xác thực chữ ký mật mã (`HMAC` trên raw body trong hằng thời gian) và kiểm tra mốc thời gian chống phát lại (replay window) trước khi xử lý nghiệp vụ hoặc đưa vào hàng đợi.
- [ ] Điểm nhận upload file áp trần dung lượng ngay ở biên, kiểm định dạng thật (magic bytes / MIME chuẩn thay vì chỉ tin tên file), sinh tên lưu trữ an toàn và đẩy file lớn thẳng lên object storage qua presigned URL thay vì giữ trong bộ nhớ API process.
- [ ] Tạo và cập nhật một nghiệp vụ nằm trong một transaction. Gọi HTTP hoặc hàng đợi ở trong transaction là BLOCK — chuyển sang ghi DB rồi phát sự kiện sau commit, hoặc outbox.

DECIDE

- [ ] Phiên bản API khi client cũ còn sống. Mobile cần chính sách tương thích rõ hơn web cùng đợt phát hành.
- [ ] `Idempotency-Key` đặt ở header hay ở khóa tự nhiên của nghiệp vụ (email, mã đơn). Cùng key mà body khác nhau thì trả xung đột.

## G2 — Cấu trúc (theo từng thay đổi)

BLOCK cho mọi thay đổi mở cổng Backend:

- [ ] Adapter nhận request (HTTP, RPC, job) và gọi use case. Luật nghiệp vụ không nằm trong adapter.
- [ ] Log tại biên giới thất bại (từ chối quyền, dependency lỗi, ghi không idempotent) gồm định danh request. Không log token, mật khẩu, hoặc body thanh toán.
- [ ] Đổi mapping lưu trữ đi kèm test ghi một hàng rồi đọc lại từ kho. Kết quả HTTP một mình không đủ.
- [ ] Không đưa giá trị bí mật vào repo. Thêm cấu hình mới thì cập nhật file mẫu tên biến môi trường.

## G2 — Chuẩn nền service

BLOCK khi dựng mới service, thêm kho/dependency bắt buộc, hoặc sửa bootstrap/cấu hình chạy. Task chỉ đổi nghiệp vụ trên nền đã đạt thì đánh dấu "trên nền có sẵn" trong brief:

- [ ] Ranh giới module hoặc package được khai. Vòng phụ thuộc cố ý thì ghi trong brief.
- [ ] Config và bí mật đọc từ môi trường lúc khởi động (thiếu cấu hình bắt buộc thì dừng sớm).
- [ ] Process có đường tắt nhẹ nhàng: ngừng nhận request mới, đợi việc đang chạy trong hạn, đóng kết nối kho dữ liệu.
- [ ] Health tách sống và sẵn sàng khi có dependency. Sống trả khi process up. Sẵn sàng trả lỗi khi kho hoặc dependency bắt buộc không dùng được.

## G2 — Test tối thiểu

BLOCK cho mỗi hành vi trong tiêu chí chấp nhận:

- [ ] Đường đúng.
- [ ] Biên từ chối: thiếu field, sai quyền, sai chủ sở hữu.
- [ ] Ghi lặp hoặc hai request song song không nhân đôi hiệu ứng, nếu đường đó retry được.
- [ ] Lỗi dependency không nuốt im. Caller nhận lỗi tường minh hoặc trạng thái đã định nghĩa.

## G3 — Cờ đỏ

- Tin response HTTP mà không đọc lại hàng đã ghi.
- `try/catch` rỗng hoặc trả 200 khi ghi thất bại.
- Kiểm tra quyền sau khi đã trừ tồn, gửi mail, hoặc publish sự kiện.
- N+1 trong vòng lặp trên danh sách trả về API. Test hoặc log số query cho đường đó.
- Secret, connection string, hoặc khóa ký trong source.

## Mở thêm

- Schema, index, migration: [database/GATES.md](../database/GATES.md)
- Timeout phía gọi ra và hạn của request: [network/GATES.md](../network/GATES.md)
- Quyết định consistency và queue: [system-design/GATES.md](../system-design/GATES.md)
