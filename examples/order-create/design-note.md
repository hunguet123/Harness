# Design note — Tạo đơn hàng idempotent (`POST /v1/orders`)

- Change brief: [change-brief.md](change-brief.md)
- Domain liên quan: Backend, Database, Network
- Ngôn ngữ & hồ sơ áp dụng (`languages/*.md`): `languages/go.md`, `languages/sql-idl.md`

## Bối cảnh

Người mua tạo đơn từ Web/Mobile (~0,2 QPS trung bình, ~10 QPS đỉnh trong chiến dịch). Không chấp nhận tạo trùng đơn khi mạng di động chập chờn retry; độ trễ mục tiêu `p95 < 400ms`, ngân sách tối đa dưới `2000ms`.

## Ánh xạ module và ranh giới

- Module thay đổi:
  - `internal/transport/http/order_handler.go` (`transport`): đọc header `Idempotency-Key`, validate body JSON, truyền `r.Context()` vào use case.
  - `internal/app/create_order.go` (`application`): kiểm quyền trên `tenant_id`, gọi `InventoryChecker` port trước transaction, sau đó mở transaction lưu `orders` + `outbox_events` + `idempotency_keys`.
  - `internal/domain/order.go` (`domain`): tính tổng tiền bằng `int64` (đơn vị đồng/xu nhỏ nhất), kiểm bất biến số lượng `> 0`.
  - `internal/postgres/order_repo.go` (`persistence`) & cấu hình timeout/retry của HTTP client tồn tại sẵn tại `internal/client/inventory/http_client.go` (`integrations`); không thêm client, pool, dependency hay bootstrap mới.
- Chiều phụ thuộc giữ nguyên / thêm mới: `transport` → `application` → `domain`; `postgres` và `client/inventory` hiện thực hóa interface khai báo trong `internal/app`.

## Quyết định

| Hạng mục / Tín hiệu | Chọn | Đánh đổi & cách hỏng | Đổi khi nào |
| --- | --- | --- | --- |
| Consistency | Mạnh trong 1 transaction Postgres cho `orders` + `outbox_events` + `idempotency_keys` | Tăng nhẹ dung lượng ghi bảng khóa; đổi lại không bao giờ lệch giữa đơn và sự kiện | Khi write QPS vượt ngưỡng 1 cụm Postgres chính (> 5 000 write/s) |
| Nguồn sự thật | Bảng `orders` trên PostgreSQL 16 | Mất kết nối Postgres thì từ chối tạo đơn mới (`503`), không xếp hàng mù | Khi nghiệp vụ cho phép nhận đơn tạm lúc bảo trì kho |
| Idempotency của ghi | Header `Idempotency-Key` (UUID/chuỗi <= 128 ký tự), unique `(tenant_id, actor_id, key)` kèm cột `payload_hash` (SHA-256) | Cần dọn các khóa quá 7 ngày bằng job `retention` | Giữ cố định vì là bất biến nghiệp vụ |
| Ngân sách timeout & retry | Proxy `5000ms` > Server handler `2000ms` > Inventory RPC `600ms` (timeout không retry; chỉ retry tối đa 1 lần với backoff `80ms` khi nhận `503` sớm vì là câu đọc kiểm tra) + DB `400ms` | Inventory treo trả `504 INVENTORY_TIMEOUT` sau `600ms`; nếu trả `503` sớm thì một retry vẫn nằm trong ngân sách handler, người dùng có thể gửi lại cùng `Idempotency-Key` an toàn | Điều chỉnh khi `p99` của `inventory-service` thay đổi |

## Hợp đồng

- `POST /v1/orders` (bắt buộc header `Authorization` và `Idempotency-Key`)
- Thành công: `201 Created` (lần đầu) hoặc `200 OK` (gửi lại khớp `payload_hash`) — `{"order_id":"ord_01J...","status":"PENDING","total_minor":250000}`
- Lỗi chuẩn: `400 INVALID_INPUT` · `403 FORBIDDEN` · `409 IDEMPOTENCY_CONFLICT` · `422 OUT_OF_STOCK` · `504 INVENTORY_TIMEOUT`

## Cách hỏng

1. `inventory-service` chậm/chết: hủy ở `600ms`, không retry timeout, trả `504` kèm `request_id`; nếu service trả `503` trước deadline thì retry đọc tối đa 1 lần sau `80ms`. Chưa ghi gì vào DB.
2. Client timeout rồi gửi lại cùng `Idempotency-Key`: nếu request đầu đã commit thì trả lại body đã lưu; nếu request đầu đang chạy đồng thời thì khóa unique chặn tạo hàng thứ hai.
3. Client tái sử dụng nhầm `Idempotency-Key` cũ cho giỏ hàng khác: khác `payload_hash` → trả ngay `409 IDEMPOTENCY_CONFLICT`.

## Cố ý chưa làm

Chưa tách shard bảng `orders`: với ~0,2 QPS (~6,3 triệu hàng/năm), một cụm Postgres kèm index `(tenant_id, created_at DESC)` dư sức chịu tải; chỉ xét phân vùng theo tháng khi bảng vượt `50 triệu` hàng.
