# Hồ sơ dự án (Project Profile)

File này lưu sự thật riêng của dự án đích tại `harness/PROJECT.md` (không bị ghi đè khi chạy lại `install.sh`). Chạy skill `onboard-project` ở lần đầu gắn Harness để xác minh và điền đầy đủ.

- Dự án:
- Ngày cập nhật:
- Ngôn ngữ & framework chính:
- Cơ sở dữ liệu & hạ tầng phụ:

## 1. Lệnh kiểm chứng chuẩn của dự án (G2 Sensors)

Chỉ ghi lệnh thực tế đã chạy thử thành công trong repo này:

- Kiểm kiểu tĩnh (Typecheck):
- Linter & kiểm ranh giới module:
- Unit test:
- Integration / End-to-end test:
- Build:

## 2. Ánh xạ thư mục vào Bản đồ Module

Ghi đường dẫn thư mục thật của repo ứng với vai trò module trong `GATES.md` (mảng nào không có thì ghi `K/A`):

- Entrypoint / Bootstrap (`cmd`, `main`, `app-shell`):
- Biên giao tiếp (`transport`, `controllers`, `features-ui`):
- Điều phối nghiệp vụ (`application`, `use-cases`, `sync-outbox`):
- Lõi nghiệp vụ thuần (`domain`, `core-domain` — cấm import HTTP/ORM/SDK ngoài):
- Lưu trữ & truy vấn (`persistence`, `local-store`, `migrations`):
- Tích hợp & việc nền (`integrations`, `jobs`, `remote-client`):

## 3. Ranh giới quyền hạn của Agent (Escalation)

Các thay đổi sau bắt buộc dừng hỏi và chốt `design-note.md` trước khi sửa code:

- Đổi schema xóa/siết cột đang có dữ liệu hoặc đổi khóa phân mảnh/tenant.
- Đổi cơ chế xác thực, phân quyền, chữ ký mật mã hoặc luồng thanh toán/tiền tệ.
- Thêm dependency hạ tầng mới (queue, cache, dịch vụ trả phí bên thứ ba) hoặc phá tương thích ngược API public.

## 4. Bẫy lịch sử cần tránh trên repo này (Known Footguns)

Ghi ngắn gọn các điểm dễ sập riêng của codebase này (kèm link `failure-memory` nếu có):

1.
