# Backend

Mở khi đổi API, use case, phân quyền, job, hoặc tích hợp. Cổng này không gắn framework. Lệnh unit, integration, lint, và build là lệnh của project đích, ghi trong change brief.

Nguồn tinh chỉnh: cổng xong của [harness-kit](https://github.com/romabeckman/harness-kit/blob/main/agents/developer-backend.md), bản đồ [backend-things](https://github.com/rendyspratama/backend-things), cặp engineer/reviewer của [harness-claude-code](https://github.com/MartinKChen/harness-claude-code).

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
- [ ] Phán quyền chạy trước khi đổi trạng thái. Đọc hoặc ghi theo chủ sở hữu kiểm tra đúng resource của actor đó, không chỉ "đã đăng nhập".
- [ ] Ghi có thể bị client, job, hoặc webhook gửi lại thì có khóa idempotency hoặc ràng buộc unique. Gửi lại trả kết quả lần đầu, không tạo bản thứ hai.
- [ ] Tạo và cập nhật một nghiệp vụ nằm trong một transaction. Gọi HTTP hoặc hàng đợi ở trong transaction là BLOCK — chuyển sang ghi DB rồi phát sự kiện sau commit, hoặc outbox.

DECIDE

- [ ] Phiên bản API khi client cũ còn sống. Mobile cần chính sách tương thích rõ hơn web cùng đợt phát hành.
- [ ] `Idempotency-Key` đặt ở header hay ở khóa tự nhiên của nghiệp vụ (email, mã đơn). Cùng key mà body khác nhau thì trả xung đột.

## G2 — Cấu trúc

BLOCK

- [ ] Adapter nhận request (HTTP, RPC, job) và gọi use case. Luật nghiệp vụ không nằm trong adapter.
- [ ] Ranh giới module hoặc package được khai. Vòng phụ thuộc cố ý thì ghi trong brief.
- [ ] Config và bí mật đọc từ môi trường. Repo có ví dụ tên biến, không có giá trị thật.
- [ ] Log tại biên giới thất bại (từ chối quyền, dependency lỗi, ghi không idempotent) gồm định danh request. Không log token, mật khẩu, hoặc body thanh toán.
- [ ] Process có đường tắt nhẹ nhàng: ngừng nhận request mới, đợi việc đang chạy trong hạn, đóng kết nối kho dữ liệu.
- [ ] Health tách sống và sẵn sàng khi có dependency. Sống trả khi process up. Sẵn sàng trả lỗi khi kho hoặc dependency bắt buộc không dùng được.
- [ ] Đổi mapping lưu trữ đi kèm test ghi một hàng rồi đọc lại từ kho. Kết quả HTTP một mình không đủ.

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
