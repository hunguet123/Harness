# C# và .NET

Áp dụng cho **Backend / API** (ASP.NET Core Minimal APIs / Controllers, gRPC), **Background Workers** (`BackgroundService` / Hangfire / MassTransit), và **App đa nền tảng** (.NET MAUI). Đọc kèm cổng: [backend](../backend/GATES.md), [database](../database/GATES.md), [network](../network/GATES.md).

## Tổ chức module và khóa ranh giới

- Tách Solution thành các project `.csproj` để MSBuild cưỡng bức chiều phụ thuộc một chiều:
  - `*.Domain`: entity, value object (`readonly record struct` / `record`), domain error/result. Không tham chiếu gói ASP.NET Core, EF Core, hay SDK bên ngoài.
  - `*.Application`: use case / command-query handlers, interface cổng ra, validation biên (`FluentValidation` / DataAnnotations). Chỉ tham chiếu `*.Domain`.
  - `*.Infrastructure`: EF Core `DbContext` / Dapper, repository, outbox, HTTP clients, message consumers.
  - `*.Api` / `*.Worker`: `Program.cs` bootstrap, endpoints/controllers, auth policies, middleware lỗi chuẩn (`ProblemDetails`), health checks (`/health/live`, `/health/ready`).
- Với dự án lớn hoặc modular monolith trong một solution, thêm test kiến trúc bằng `NetArchTest` hoặc `ArchUnitNET` chặn phụ thuộc chéo giữa các miền.

## Ràng buộc bắt buộc (BLOCK)

- **Bật `<Nullable>enable</Nullable>` và xử lý cảnh báo:** khai báo rõ kiểu có thể `null` ở mọi DTO, entity và chữ ký hàm.
- **Truyền `CancellationToken` xuyên suốt:** mọi endpoint ASP.NET Core, message handler và `BackgroundService` nhận `CancellationToken` và truyền tới tận `HttpClient`, EF Core (`ToListAsync(ct)`, `SaveChangesAsync(ct)`), Dapper (`CommandDefinition(..., cancellationToken: ct)`).
- **Cấm chặn luồng bất đồng bộ (sync-over-async):** không gọi `.Result`, `.Wait()`, hay `.GetAwaiter().GetResult()` trên `Task` gây cạn thread pool hoặc deadlock. Không dùng `async void` (trừ event handler bắt buộc của UI có `try/catch` trọn vẹn).
- **Quản lý `HttpClient` và vòng đời DI:**
  - Luôn đăng ký `HttpClient` qua `IHttpClientFactory` / typed client kèm cấu hình timeout và resilience (`Microsoft.Extensions.Http.Resilience`), cấm `new HttpClient()` theo từng request gây cạn cổng socket (`SocketExhaustion`).
  - Không tiêm dịch vụ `Scoped` (như `DbContext`) vào dịch vụ `Singleton` (captive dependency); bật `ValidateScopes` và `ValidateOnBuild`.
- **EF Core chuẩn đường nóng:** dùng `.AsNoTracking()` cho mọi câu truy vấn chỉ đọc; dùng `decimal` cho tiền tệ kèm cấu hình `HasPrecision(p, s)` rõ ràng trong mapping.

## Lệnh kiểm chứng chuẩn cho G2

- Build kiểm lỗi: `dotnet build --no-restore -warnaserror`
- Định dạng & analyzer: `dotnet format --verify-no-changes`
- Test: `dotnet test --no-build`

## Cờ đỏ khi soát G3

- Trả thẳng `IQueryable<T>` hoặc EF Core entity chưa chiếu (`Select` sang DTO) ra ngoài tầng `Application`/`Api`, gây nổ truy vấn N+1 hoặc lộ cột nhạy cảm.
- Nuốt `OperationCanceledException` trong vòng lặp `BackgroundService` rồi tiếp tục chạy thay vì thoát êm khi process đang tắt.
- Đặt chính sách retry của Polly/Resilience chồng lên retry sẵn có của SDK (như Azure SDK / MassTransit) trên thao tác không có khóa idempotency.
