# Rust

Áp dụng cho **Backend độ trễ thấp**, **Network / Gateway / Proxy**, **Worker chịu tải**, và **CLI / Engine nhúng** (`axum`, `tonic`, `tokio`, `sqlx`). Đọc kèm cổng: [backend](../backend/GATES.md), [database](../database/GATES.md), [network](../network/GATES.md).

## Tổ chức module và khóa ranh giới

- Với dịch vụ vừa/lớn, dùng **Cargo Workspace** tách thành các crate để chính trình biên dịch `rustc` cấm vòng phụ thuộc và khóa ranh giới:
  - `crates/domain`: kiểu miền mạnh (newtype pattern như `OrderId`, `Money`), luật bất biến, lỗi miền với `thiserror`. Không phụ thuộc `axum`, `tonic`, `sqlx`, hay `reqwest`.
  - `crates/application`: use case, trait cho repository/client, điều phối transaction.
  - `crates/adapters-*` (`http`, `grpc`, `postgres`, `worker`, `clients`): hiện thực hóa trait và ánh xạ dữ liệu biên.
  - `bins/<ten-service>`: đọc cấu hình, khởi tạo tracing/pool, nối các crate và bắt tín hiệu tắt nhẹ nhàng (`with_graceful_shutdown`).
- Trong một crate đơn, giới hạn hiển thị bằng `pub(crate)` / `pub(super)` thay vì mở `pub` toàn bộ.

## Ràng buộc bắt buộc (BLOCK)

- **Cấm làm sập luồng phục vụ bằng `.unwrap()` / `.expect()`:** mọi đường xử lý request, message, dữ liệu từ DB hoặc mạng phải trả `Result<T, E>` (bật lint `clippy::unwrap_used` hoặc kiểm nghiêm ở code sản phẩm; `.expect()` chỉ chấp nhận khi khởi động process với bất biến cấu hình đã giải thích).
- **Không chặn luồng thực thi của `tokio`:** trong hàm `async fn`, không gọi I/O đồng bộ (`std::fs`, `std::net`, `std::thread::sleep`) hoặc tính toán CPU dài quá vài trăm micro-giây. Chuyển việc nặng sang `tokio::task::spawn_blocking` hoặc threadpool riêng có giới hạn.
- **Cancel-safety khi dùng `tokio::select!` và timeout:** khi bọc một future trong `tokio::time::timeout` hoặc nhánh `select!`, đảm bảo việc hủy nhánh thua không làm mất nửa chừng dữ liệu đã đọc từ channel/stream hay bỏ dở trạng thái ghi cục bộ.
- **Client và Pool có hạn mức:** `reqwest::Client` được tạo một lần kèm `connect_timeout`, `timeout`, giới hạn pool và chia sẻ qua `Arc`/clone nội bộ; `sqlx::PgPool` đặt `max_connections` và `acquire_timeout`.

## Lệnh kiểm chứng chuẩn cho G2

- Kiểm biên dịch mọi target: `cargo check --workspace --all-targets`
- Linter nghiêm ngặt: `cargo clippy --workspace --all-targets -- -D warnings`
- Định dạng: `cargo fmt --all -- --check`
- Test: `cargo nextest run` hoặc `cargo test --workspace`
- Kiểm câu SQL tĩnh (nếu dùng `sqlx` offline): `cargo sqlx prepare --check`

## Cờ đỏ khi soát G3

- Giữ `std::sync::MutexGuard` đi xuyên qua điểm `.await` (làm nghẽn worker thread hoặc không biên dịch được `Send`).
- Dùng `unsafe` để tắt kiểm tra mượn/đồng thời mà không có khối `// SAFETY:` chứng minh bất biến và không chạy `cargo miri test` (khi áp dụng được).
- Clone cả bộ đệm lớn một cách thừa thãi trên đường nóng thay vì dùng tham chiếu, `Bytes`, hoặc `Arc`.
- Trả lỗi `anyhow::Error` thô ra thẳng biên API làm mất phân loại mã lỗi nghiệp vụ với lỗi hệ thống.
