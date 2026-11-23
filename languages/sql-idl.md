# SQL Engines, Cache và Hợp đồng Giao tiếp (IDL)

Áp dụng khi làm việc với **Database** ([database/GATES.md](../database/GATES.md)) và **Hợp đồng biên API / Sự kiện** ([backend/GATES.md](../backend/GATES.md), [network/GATES.md](../network/GATES.md)).

## 1. Khác biệt bắt buộc giữa các Database Engine

Không mang giả định của engine này áp sang engine khác:

### PostgreSQL
- **Online DDL:** hỗ trợ DDL trong transaction, **nhưng** `CREATE INDEX CONCURRENTLY` và `DROP INDEX CONCURRENTLY` không được chạy bên trong khối `BEGIN … COMMIT` (phải tách thành file/bước migration chạy ngoài transaction).
- **Khóa bảng:** luôn đặt `SET lock_timeout = '2s'` (hoặc ngưỡng đã chốt) đầu phiên migration để tránh xếp hàng khóa làm treo toàn bộ truy vấn đọc/ghi đứng sau.
- **Thêm ràng buộc bảng lớn:** thêm `CHECK (...) NOT VALID` (chỉ giữ khóa tích tắc) rồi chạy `VALIDATE CONSTRAINT` ở bước sau; từ PG 12+, `VALIDATE CONSTRAINT` của `IS NOT NULL` giúp `ALTER COLUMN ... SET NOT NULL` không phải quét khóa toàn bảng.
- **Kiểu chuẩn:** dùng `timestamptz` (không dùng `timestamp` mất múi giờ), `numeric(p, s)` hoặc `bigint` đơn vị nhỏ nhất cho tiền, `text` kèm `CHECK (char_length(...) <= N)` hoặc `varchar(N)`.
- **Đo plan:** `EXPLAIN (ANALYZE, BUFFERS)` trên dữ liệu tương đương thực tế.

### MySQL / InnoDB
- **Cảnh báo lớn nhất — DDL tự động `COMMIT` ngầm:** mọi lệnh `ALTER TABLE`, `CREATE INDEX`, `DROP TABLE` trong MySQL đều gây implicit commit cho transaction trước đó và **không thể rollback** khi migration gãy giữa chừng. Mỗi bước DDL phải đứng riêng và có kịch bản kiểm tra/phục hồi rõ ràng.
- **Online DDL:** chỉ rõ `ALGORITHM=INPLACE, LOCK=NONE` (hoặc `ALGORITHM=INSTANT` cho cột thêm cuối bảng khi phiên bản hỗ trợ). Với bảng lớn mà thao tác bắt buộc copy bảng, dùng công cụ đổi online (`gh-ost` / `pt-online-schema-change`).
- **Chuẩn bảng:** bắt buộc InnoDB, bộ mã `utf8mb4`, khóa chính gom cụm (clustered PK) gọn và tăng dần để tránh phân mảnh trang index; đo bằng `EXPLAIN FORMAT=JSON` hoặc `EXPLAIN ANALYZE`.

### SQLite (Mobile / Embedded / Edge)
- **Mặc định SQLite tắt khóa ngoại:** bắt buộc bật `PRAGMA foreign_keys = ON;` trên mọi kết nối mở ra và `PRAGMA journal_mode = WAL;` kèm `PRAGMA busy_timeout = ...` để đọc không bị chặn bởi ghi.
- **Một người ghi tại một thời điểm:** giữ transaction ghi cực ngắn, không tính toán hay gọi mạng giữa `BEGIN IMMEDIATE` và `COMMIT`.

### Redis / In-Memory Store
- Chỉ dùng làm **cache, rate-limit, distributed lock có thời hạn, hoặc hàng đợi tạm** trừ khi kiến trúc đã chứng minh cấu hình bền vững; không mặc định coi Redis là nguồn sự thật duy nhất cho dữ liệu không được phép mất.
- Mọi key cache bắt buộc có `TTL` (cộng thêm độ lệch ngẫu nhiên nhỏ nếu sợ hết hạn đồng loạt — cache stampede). Cấm gọi `KEYS *` hay `FLUSHALL` trên đường chạy sản phẩm; dùng `SCAN` theo lô hoặc tổ chức key theo không gian tên `tenant:entity:id:version`.

---

## 2. Hợp đồng biên và IDL (OpenAPI, Protobuf/gRPC, GraphQL)

- **Một nguồn sự thật cho hợp đồng:** khi có nhiều client (Web, iOS, Android, dịch vụ khác), định nghĩa hợp đồng trong file đặc tả (`openapi.yaml`, `*.proto`, `schema.graphql`) và sinh kiểu/client tự động thay vì chép tay hai bên.
- **Luật tương thích ngược (BLOCK khi còn client cũ đang chạy):**
  - **OpenAPI / JSON REST:** chỉ thêm trường mới ở dạng tùy chọn (client cũ bỏ qua trường lạ); không đổi tên, đổi kiểu, hay biến trường tùy chọn thành bắt buộc trên cùng phiên bản đường dẫn. Kiểm tra gãy hợp đồng bằng `oasdiff breaking`.
  - **Protobuf / gRPC:** **tuyệt đối không đổi số thứ tự tag** của trường đang có; khi xóa trường phải đánh dấu `reserved <tag_number>; reserved "<field_name>";` để không ai vô tình tái sử dụng. Kiểm tra bằng `buf lint` và `buf breaking`.
  - **GraphQL:** đánh dấu `@deprecated(reason: "...")` và quan sát lưu lượng về `0` trước khi gỡ field khỏi schema.
- **Sự kiện và Webhook:** payload sự kiện có `event_id` (để người nhận dedupe vào bảng `inbox`), `occurred_at`, `schema_version`, và chữ ký `HMAC` kèm mốc thời gian nếu đi qua mạng ngoài.
