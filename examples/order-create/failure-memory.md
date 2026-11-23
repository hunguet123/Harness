# Gửi trùng `Idempotency-Key` với body khác trả nhầm `200` thay vì `409`

- Ngày: 2026-11-23
- Project: `order-service` (ví dụ mẫu chuẩn của Harness)
- Mức: rủi ro dữ liệu / dễ lặp khi review

## Tóm tắt

Ở bản nháp đầu tiên, khi gặp trùng `(tenant_id, actor_id, idempotency_key)`, repository trả ngay kết quả đã lưu mà quên so sánh `payload_hash` của request mới với bản gốc. Nếu client sinh lỗi tái sử dụng key cũ cho một đơn hàng có mặt hàng khác, hệ thống âm thầm trả `200` với đơn cũ khiến người dùng tưởng đơn mới đã được đặt.

## Nguyên nhân

Câu truy vấn `ON CONFLICT (tenant_id, actor_id, idempotency_key) DO NOTHING` chỉ lấy lại `response_body` mà không lưu và đối chiếu cột `payload_hash` ở tầng `application`.

## Phát hiện

- **Test tự động:** thêm ca kiểm thử tích hợp `TestCreateOrder_SameKeyDifferentPayload_Returns409` trong `internal/transport/http/order_handler_test.go`.
- **Cổng đối chiếu:** mục DECIDE/BLOCK về `Idempotency-Key` trong `backend/GATES.md` ("Cùng key, tham số khác → trả xung đột `409`"); hồ sơ Go bổ sung yêu cầu chạy test integration/race tương ứng.

## Bằng chứng

- File mẫu: [change-brief.md](change-brief.md) (Tiêu chí chấp nhận #2) và [design-note.md](design-note.md) (Cách hỏng #3).
