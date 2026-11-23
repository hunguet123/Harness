# Change brief — Tạo đơn hàng idempotent (`POST /v1/orders`)

- Ngày: 2026-11-23
- Project: `order-service` (ví dụ mẫu chuẩn của Harness)
- Stack (ngôn ngữ, framework, database): Go 1.24, `chi`, PostgreSQL 16 (`sqlc`)
- Hồ sơ ngôn ngữ mở (`languages/*.md`): `languages/go.md`, `languages/sql-idl.md`
- Module bị đụng (theo bản đồ trong `GATES.md`): `backend` (`transport`, `application`, `domain`, `persistence`), `database` (`schema-constraints`, `migrations`, `outbox-lifecycle`), `network` (`resilience-policy`)
- Một câu hành vi: Khách đã đăng nhập gửi `POST /v1/orders` kèm `Idempotency-Key` để tạo đơn và ghi sự kiện `order.created` vào bảng `outbox`; gửi lại cùng key trả đúng đơn đầu tiên, cùng key khác payload trả `409`.

## Phạm vi

- Trong phạm vi: Endpoint `POST /v1/orders`, bảng `orders` + `idempotency_keys` + `outbox_events`, gọi kiểm tồn kho qua HTTP client đã có sẵn sang `inventory-service` với deadline trước khi mở transaction ghi DB; không tạo client/pool/dependency hay sửa bootstrap.
- Ngoài phạm vi: Xử lý thanh toán cổng ngoài và tiến trình worker đọc `outbox_events` đẩy lên Kafka.
- Loại thay đổi:
  - [x] Sửa/thêm nghiệp vụ trên nền có sẵn (kiểm mục **Theo từng thay đổi**; chuẩn nền giữ nguyên)
  - [ ] Dựng mới service / thêm client hoặc dependency ngoài / sửa bootstrap-vận hành (kiểm cả **Chuẩn nền service**)

## Domain

- [ ] System Design — `system-design/GATES.md`
- [x] Backend — `backend/GATES.md`
- [x] Database — `database/GATES.md`
- [x] Network — `network/GATES.md`
- [ ] Frontend — `frontend/GATES.md`
- [ ] Mobile — `mobile/GATES.md`

Mục không áp dụng (một dòng lý do mỗi mục):
- Phân trang danh sách (`backend/GATES.md`): chỉ thêm endpoint tạo đơn lẻ, không trả danh sách.
- Online backfill (`database/GATES.md`): bảng mới hoàn toàn chưa có dữ liệu cũ; vẫn đặt `SET lock_timeout = '2s'`.

## Tiêu chí chấp nhận

1. Request hợp lệ trả `201 Created` kèm mã đơn; đọc lại DB có đủ 1 hàng `orders` và 1 hàng `outbox_events` cùng `tenant_id` của actor.
2. Gửi lại cùng `(tenant_id, actor_id, idempotency_key)` và cùng `payload_hash` (kể cả 2 goroutine song song) chỉ tạo 1 đơn và trả kết quả lần đầu; khác `payload_hash` trả `409 IDEMPOTENCY_CONFLICT`.
3. `inventory-service` treo quá `600ms` thì request hủy qua `ctx` và trả `504 INVENTORY_TIMEOUT`, không mở transaction ghi DB.

## Ranh giới

- [x] Có — link design note: [design-note.md](design-note.md)
- [ ] Không

## Đối chiếu cổng áp dụng

| File / section | Mục BLOCK hoặc DECIDE | Kết quả | Bằng chứng hoặc lý do không áp dụng |
| --- | --- | --- | --- |
| `backend/GATES.md` / Theo từng thay đổi | Auth actor/tenant tại application; validation biên; lỗi ổn định | PASS | Integration test kiểm `tenant_id`, DTO và mã `400/403/409/422/504` |
| `backend/GATES.md` / Ghi & idempotency | Unique key + payload hash; transaction ngắn; outbox cùng transaction | PASS | Migration + test 10 request song song, design note mục Idempotency |
| `backend/GATES.md` / Webhook, upload, pagination | Không thuộc endpoint tạo đơn | N/A | Không nhận webhook/file và không trả collection |
| `database/GATES.md` / Schema & migration | Constraint DB, lock timeout, đường rollback | PASS | Bảng mới; migration đặt `lock_timeout`, unique/foreign/check constraints |
| `database/GATES.md` / Query & concurrency | Index theo lookup thật; thử race; `EXPLAIN` | PASS | `idx_idempotency_lookup`, test race và plan `0.08 ms` |
| `network/GATES.md` / Timeout & retry | Deadline giảm dần; timeout không retry; chỉ retry `503` một lần | PASS | Design note ngân sách `5000 > 2000 > 600ms`; integration timeout |
| `network/GATES.md` / Idempotency | Retry phía client không tạo đơn thứ hai | PASS | Cùng key trả đơn đầu, khác payload trả `409` |
| `network/GATES.md` / Chuẩn nền client | Không tạo client/pool/dependency/bootstrap mới | N/A | Dùng HTTP client tồn tại sẵn, ghi rõ trong phạm vi và design note |
| `languages/go.md`, `languages/sql-idl.md` | Context, race, đóng tài nguyên; IDL tương thích và SQL đúng engine | PASS | `go vet`, `golangci-lint`, `go test -race`, integration PostgreSQL 16 |

## Bằng chứng G2

| Việc | Lệnh | Kết quả |
| --- | --- | --- |
| Unit | `go test -race ./internal/domain/... ./internal/app/...` | PASS (14 tests, 0 race) |
| Integration hoặc end-to-end | `go test -race -tags=integration ./internal/postgres/... ./internal/transport/http/...` | PASS (ghi-đọc lại DB, song song 10 request cùng key tạo đúng 1 hàng) |
| Lint | `go vet ./... && golangci-lint run` | PASS (0 issues) |
| Build | `go build ./cmd/order-api` | PASS |

Lệnh khác (EXPLAIN, kiểm tra tay):
- `EXPLAIN (ANALYZE, BUFFERS)` cho tra cứu khóa `(tenant_id, actor_id, idempotency_key)` dùng `Index Scan using idx_idempotency_lookup` (`0.08 ms`).

## G3

- [x] Đã chạy lại lệnh ở lượt hai
- [x] Diff khớp phạm vi và không vi phạm chiều phụ thuộc module (`domain` không import `net/http` hay `database/sql`)
- [x] Mỗi mục BLOCK/DECIDE áp dụng đã có dòng PASS/N/A và bằng chứng/lý do trong brief
- [x] Failure memory: [failure-memory.md](failure-memory.md)
