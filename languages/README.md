# Hồ sơ ngôn ngữ lập trình theo từng phần

Bộ cổng trong `*/GATES.md` khóa **hành vi và ranh giới module**, còn thư mục `languages/` khóa **cách hiện thực, công cụ cưỡng bức (typecheck, linter, test, khóa import), và bẫy đặc thù của từng ngôn ngữ**.

- **Dự án đã có:** dùng đúng ngôn ngữ hiện hữu của repo (script `install.sh` tự dò qua manifest) và mở hồ sơ tương ứng dưới đây.
- **Dự án mới:** chọn ngôn ngữ ở cổng G0/G1 theo ma trận dưới đây, ghi vào `change-brief.md`, rồi áp đúng bộ công cụ kiểm chứng ngay từ commit đầu tiên.

## Ma trận ngôn ngữ cho từng phần

### 1. Backend & Worker

- **TypeScript (Node.js / Bun — NestJS, Fastify, Hono):** hợp đội ngũ chia sẻ kiểu/schema với Web & React Native, tốc độ ra tính năng nhanh, I/O mạng lớn. Tránh cho tác vụ ngốn CPU dài trên luồng chính. Hồ sơ: [typescript.md](typescript.md).
- **Go (stdlib, chi, gin, connect-go, sqlc):** hợp dịch vụ API/RPC chịu tải cao, proxy, worker đồng thời lớn, triển khai một binary nhẹ, dễ đọc chéo giữa người và agent. Hồ sơ: [go.md](go.md).
- **Python (FastAPI, Django, Celery/Temporal + uv):** hợp dịch vụ gắn chặt xử lý dữ liệu, AI/ML pipeline, tự động hóa hoặc tích hợp nhanh; bắt buộc bật kiểm kiểu tĩnh nghiêm ngặt. Hồ sơ: [python.md](python.md).
- **Java / Kotlin (Spring Boot, Ktor, Quarkus):** hợp hệ thống nghiệp vụ phức tạp nhiều miền, giao dịch tài chính/doanh nghiệp lớn, hệ sinh thái Kafka/JDBC chín muồi và khóa kiến trúc bằng ArchUnit. Hồ sơ: [jvm.md](jvm.md).
- **Rust (axum, tonic, tokio, sqlx):** hợp dịch vụ đòi độ trễ đuôi (`p99`) thấp và ổn định, gateway/network data-plane, worker xử lý dữ liệu nặng không chấp nhận GC pause. Hồ sơ: [rust.md](rust.md).
- **C# / .NET (ASP.NET Core, EF Core / Dapper):** hợp hệ thống doanh nghiệp hiệu năng cao, kiểu tĩnh mạnh, tích hợp sẵn DI/resilience/observability đồng bộ. Hồ sơ: [csharp.md](csharp.md).

### 2. Frontend Web

- **TypeScript (React/Next.js, Vue/Nuxt, Angular, SvelteKit):** chuẩn mặc định cho mọi màn hình web sản xuất để khóa hợp đồng DTO, state giao diện và thuộc tính accessibility ngay lúc biên dịch. JavaScript không kiểm kiểu chỉ chấp nhận cho script nhúng nhỏ đã ghi lý do trong brief. Hồ sơ: [typescript.md](typescript.md).

### 3. Mobile

- **Swift (SwiftUI / UIKit):** app iOS thuần, cần khai thác sâu API hệ thống Apple, hiệu năng UI gốc, Keychain/SwiftData/BackgroundTasks trực tiếp. Hồ sơ: [mobile-swift-dart.md](mobile-swift-dart.md).
- **Kotlin (Jetpack Compose / Android gốc & Kotlin Multiplatform):** app Android thuần hoặc chia sẻ tầng `domain` + `local-store` + `sync-outbox` đa nền tảng qua KMP trong khi giữ UI gốc. Hồ sơ: [jvm.md](jvm.md).
- **Dart (Flutter):** một codebase giao diện và đồng bộ offline đồng nhất trên iOS/Android, kiểm soát pixel riêng. Hồ sơ: [mobile-swift-dart.md](mobile-swift-dart.md).
- **TypeScript (React Native / Expo):** chia sẻ năng lực TypeScript và logic dữ liệu với đội Web, hệ sinh thái OTA/UI phong phú. Hồ sơ: [typescript.md](typescript.md).

### 4. Database & Hợp đồng mạng (IDL)

- **SQL & Kho dữ liệu (PostgreSQL, MySQL, SQLite, Redis):** mỗi engine có luật khóa bảng và transaction DDL khác hẳn nhau; không mang thói quen Postgres sang MySQL hay SQLite. Hồ sơ: [sql-idl.md](sql-idl.md).
- **IDL giao tiếp (OpenAPI, Protobuf/gRPC, GraphQL):** khóa hợp đồng giữa các dịch vụ và giữa Backend với Frontend/Mobile trước khi sinh code. Hồ sơ: [sql-idl.md](sql-idl.md).

## Dấu hiệu nhận diện tự động trong repo đã có

- `package.json`, `tsconfig.json`, `deno.json` → [typescript.md](typescript.md)
- `go.mod` → [go.md](go.md)
- `pyproject.toml`, `requirements.txt`, `Pipfile` → [python.md](python.md)
- `pom.xml`, `build.gradle`, `build.gradle.kts` → [jvm.md](jvm.md)
- `Cargo.toml` → [rust.md](rust.md)
- `*.csproj`, `*.sln` → [csharp.md](csharp.md)
- `Package.swift`, `*.xcodeproj`, `pubspec.yaml` → [mobile-swift-dart.md](mobile-swift-dart.md)
- `*.sql`, `*.proto`, `openapi.*`, `schema.prisma`, thư mục `migrations/` → [sql-idl.md](sql-idl.md)
