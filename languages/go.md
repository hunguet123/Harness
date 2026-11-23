# Go

Áp dụng cho **Backend**, **Network / Gateway**, **Worker đồng thời**, và **CLI**. Đọc kèm cổng: [backend](../backend/GATES.md), [database](../database/GATES.md), [network](../network/GATES.md).

## Tổ chức module và khóa ranh giới

- `cmd/<ten-service>/main.go` chỉ làm `bootstrap`: đọc config, khởi tạo logger/pool/client, nối dependency, chạy server và bắt tín hiệu tắt (`signal.NotifyContext`). Không đặt luật nghiệp vụ trong `cmd/`.
- Đặt code riêng của dịch vụ dưới `internal/` để chính trình biên dịch Go chặn import trái phép từ ngoài:
  - `internal/domain`: struct nghiệp vụ, kiểu định danh, lỗi miền (`var Err... = errors.New(...)`). Không import `net/http`, `database/sql`, hay SDK hãng ngoài.
  - `internal/app` (use cases): điều phối nghiệp vụ, khai báo `interface` nhỏ ngay tại nơi gọi (consumer-defined interfaces).
  - `internal/transport/http` (hoặc `grpc`), `internal/postgres` (hoặc `sqlc`), `internal/worker`, `internal/client/<ten>`: các adapter hiện thực hóa interface và xử lý I/O.
- Khi repo lớn có nhiều miền dưới `internal/`, dùng `go-arch-lint` hoặc `depguard` trong `golangci-lint` để chặn import vòng/chéo giữa các miền.

## Ràng buộc bắt buộc (BLOCK)

- **`context.Context` đi đầu mọi hàm I/O:** mọi hàm gọi mạng, DB, cache, hàng đợi nhận `ctx context.Context` làm tham số đầu tiên để truyền deadline, hủy tác vụ và trace id. Không cất `Context` vào trong `struct`.
- **Không dùng `http.DefaultClient` hay `http.Server` mặc định:** luôn khởi tạo `&http.Client{Timeout: ...}` kèm `Transport` có trần kết nối, và `&http.Server{ReadHeaderTimeout: ..., ReadTimeout: ..., WriteTimeout: ..., IdleTimeout: ...}`.
- **Quản lý vòng đời goroutine:** mọi `go func()` phải có điều kiện dừng rõ ràng (`ctx.Done()` hoặc đóng channel) và nơi chờ kết thúc (`sync.WaitGroup` / `errgroup.Group`). Fan-out bắt buộc giới hạn đồng thời (`errgroup.SetLimit(n)` hoặc semaphore).
- **Xử lý lỗi tường minh:** bọc ngữ cảnh bằng `fmt.Errorf("...: %w", err)`, kiểm tra lỗi bằng `errors.Is` / `errors.As`. Phân biệt rõ `sql.ErrNoRows` (trả `404` / không tìm thấy) với lỗi kết nối kho (`5xx`).
- **Đóng tài nguyên và kiểm lỗi phần đọc:** luôn `defer rows.Close()` kèm kiểm `rows.Err()` sau vòng lặp `rows.Next()`; đọc hết hoặc giới hạn `http.MaxBytesReader` và `defer resp.Body.Close()` để tái sử dụng kết nối TCP.

## Lệnh kiểm chứng chuẩn cho G2

- Kiểm tĩnh cơ bản: `go vet ./...`
- Linter tổng hợp: `golangci-lint run` (bật `errcheck`, `govet`, `staticcheck`, `bodyclose`, `sqlclosecheck`, `contextcheck`)
- Test kèm dò tranh chấp bộ nhớ: `go test -race ./...`
- Build: `go build ./...`

## Cờ đỏ khi soát G3

- Gọi `context.Background()` hoặc `context.TODO()` bên trong handler đang có sẵn `r.Context()`, làm đứt deadline và trace.
- Truy cập `map` hoặc biến dùng chung từ nhiều goroutine mà không có `sync.Mutex` / `sync.RWMutex`.
- Bỏ qua lỗi trả về bằng `_ = ...` ở thao tác ghi, commit/rollback transaction (`defer tx.Rollback()` là an toàn, nhưng lỗi `tx.Commit()` bắt buộc phải kiểm).
- Ghép chuỗi `fmt.Sprintf` để tạo câu SQL có dữ liệu người dùng thay vì placeholder `$1` / `?` hoặc `sqlc`.
