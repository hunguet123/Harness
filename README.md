# Harness làm phần mềm

Bộ chuẩn để bắt đầu, làm, và kết thúc một thay đổi trong sáu mảng: Mobile, Frontend, Backend, System Design, Database, Network.

Thư mục này là một bộ độc lập. Nó không lấy stack, script, hay quy ước từ thư mục nào khác. Mỗi task tự ghi ngôn ngữ, framework, database, và lệnh kiểm tra vào change brief.

## Gắn vào dự án mới hoặc dự án đã có

Đứng tại thư mục dự án (mới hoặc đã có code, kể cả dự án đã có sẵn `.cursor/` riêng) và chạy một lệnh:

```sh
curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh
```

Hoặc nếu đã clone repo này trên máy:

```sh
/duong/dan/harness/install.sh /duong/dan/project
```

Lệnh cài đặt an toàn và chạy lặp được (idempotent):

- Đặt tài liệu, cổng domain, hồ sơ ngôn ngữ và ví dụ chuẩn vào `harness/`, khởi tạo `harness/PROJECT.md` (giữ nguyên sau khi đã onboard), nạp rule domain (`harness-*.mdc`), rule ngôn ngữ theo đuôi file (`harness-lang-*.mdc`), 10 skill và hook bảo vệ cơ học (`.cursor/hooks/harness-guard.sh`). Installer ghi ownership vào `.cursor/harness-install-manifest`, dừng nếu artifact lõi cùng tên không thuộc Harness và chỉ xóa artifact mình sở hữu; riêng Claude skill trùng tên được giữ nguyên và ghi trạng thái `preserved`. Ghép/xác minh `.cursor/hooks.json` cần `python3`; thiếu parser thì dừng thay vì báo thành công giả.
- **Tương thích đa công cụ AI (Cursor, Claude Code, OpenAI Codex CLI, GitHub Copilot):** tự cập nhật khối đánh dấu gọn trong `AGENTS.md` ở gốc dự án mà không chạm nội dung riêng của team (thêm `--claude` nếu muốn tạo luôn shim `CLAUDE.md` + `.claude/skills/`, hoặc `--cursor-only` nếu chỉ muốn dùng `.cursor/`).
- **Dự án đã có:** tự động dò `package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`, `pom.xml`/`build.gradle*`, `*.csproj`, `Package.swift`, `pubspec.yaml`... để chỉ nạp đúng các rule ngôn ngữ mà dự án đang dùng và gợi ý lệnh kiểm chứng sơ bộ vào `harness/PROJECT.md`.
- **Dự án mới (chưa có code):** nạp sẵn trọn bộ hoặc chọn trước ngôn ngữ bằng `--lang`:
  ```sh
  curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh -s -- --lang ts,go,sql /duong/dan/new-project
  ```
- **Dùng cá nhân trên repo chung của team (không làm bẩn `git status`):** thêm `--local` để tự ghi đường dẫn vào `.git/info/exclude`:
  ```sh
  curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh -s -- --local
  ```
  Nếu repo đã track cả bộ Harness, `--local` chỉ xác minh rồi thêm exclude cá nhân, không cập nhật `--lang`/`--claude` hay sửa file team. Nếu chỉ `.cursor/hooks.json` đang được track nhưng chưa có Harness registration, lệnh cũng dừng và yêu cầu team ghép mẫu hook.
- **Kiểm tra hoặc gỡ bỏ:**
  ```sh
  curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh -s -- --check
  curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh -s -- --uninstall
  ```

Khi nâng cấp một bản Harness cũ chưa có ownership manifest, installer sẽ dừng trước khi sửa file. Sau khi kiểm tra các file tùy biến trong `harness/`, chạy lại với `--adopt-legacy` để xác nhận chỉ nhận ownership các đường dẫn thuộc bộ cũ; file mới do dự án tự thêm vẫn được giữ và gây conflict rõ ràng nếu trùng đường dẫn bản mới.

## Dùng trong 5 phút

1. Lần đầu gắn vào dự án: chạy skill `onboard-project` để quét và chốt lệnh kiểm chứng + ánh xạ thư mục thật vào `harness/PROJECT.md` (tạo từ [templates/project-profile.md](templates/project-profile.md)).
2. Đọc [HARNESS.md](HARNESS.md) và xem mẫu chuẩn ~45 dòng tại [examples/order-create/](examples/order-create/change-brief.md).
3. Copy [templates/change-brief.md](templates/change-brief.md) sang ghi chú task ở project đích (ví dụ `docs/changes/<ten-task>/change-brief.md`). Điền phạm vi, module và domain bị đụng. Không sửa trực tiếp các file mẫu trong `templates/`.
4. Mở file `GATES.md` của từng domain và `languages/*.md` tương ứng (chỉ đọc). Ghi kết quả từng mục BLOCK/DECIDE áp dụng vào bảng **Đối chiếu cổng áp dụng** trong brief; không sửa trực tiếp `GATES.md`.
5. Chạy kiểm tra và dán kết quả vào brief. Lỗi có thể lặp lại thì copy [templates/failure-memory.md](templates/failure-memory.md) (xem mẫu [examples/order-create/failure-memory.md](examples/order-create/failure-memory.md)).

Thay đổi đụng ranh giới (API, schema, hợp đồng UI, giao thức mạng, offline, hoặc thêm cạnh phụ thuộc module mới) thì copy [templates/design-note.md](templates/design-note.md) sang cạnh brief và điền trước khi viết code.

## Rule, skill, MCP

Ba lớp này nằm trong `.cursor/` của harness, theo cách GitHub đóng gói cho Cursor: rule ngắn trong `.cursor/rules/*.mdc`, skill trong `.cursor/skills/*/SKILL.md`, MCP trong `.cursor/mcp.json`. Nội dung được rút từ các skill công khai, rồi trỏ về `GATES.md` thay vì chép nguyên checklist.

| Lớp | Vai trò | File |
| --- | --- | --- |
| Rule | Ràng buộc ngắn theo domain và đuôi file ngôn ngữ | [.cursor/rules](.cursor/rules) |
| Skill | Quy trình: khảo sát dự án, chạy G0–G3, soát G3, và 6 domain | [.cursor/skills](.cursor/skills) |
| Hook | Chặn cơ học việc sửa nhầm `templates/*` hoặc commit URI/token/API-key phổ biến trong `mcp.json` | [hooks/hooks.example.json](hooks/hooks.example.json) |
| MCP | Server tùy chọn để lấy bằng chứng | [mcp/catalog.md](mcp/catalog.md) |

`mcp.json` để trống. Server còn duy trì (Chrome DevTools, Postgres read-only) chỉ được copy từ [mcp/mcp.example.json](mcp/mcp.example.json) khi task cần, và phải trả về `{"mcpServers": {}}` ngay khi hết task. Server archive như `@modelcontextprotocol/server-postgres` không dùng.

**Cách đặt trong workspace:**

- Mở trực tiếp repo này: mọi đường dẫn tính từ gốc repo (`HARNESS.md`, `templates/...`, `<domain>/GATES.md`).
- Đặt làm thư mục con `harness/` trong workspace cha và tạo symlink `.cursor -> harness/.cursor` ở thư mục cha: các đường dẫn trên có thêm tiền tố `harness/`. Lưu ý `.cursor/mcp.json` lúc đó dùng chung cho mọi project con trong workspace cha, và nếu mở riêng `harness/` trong khi symlink ở thư mục cha vẫn còn thì Cursor sẽ liệt kê rule hai lần.

## Bản đồ cổng

| Domain | Mở khi | File |
| --- | --- | --- |
| System Design | Thêm dịch vụ, đổi luồng dữ liệu, chọn consistency, ước lượng tải | [system-design/GATES.md](system-design/GATES.md) |
| Backend | API, use case, auth, job, tích hợp | [backend/GATES.md](backend/GATES.md) |
| Database | Bảng, index, migration, transaction, truy vấn nóng | [database/GATES.md](database/GATES.md) |
| Network | Timeout, retry, TLS, pool, giới hạn tải, health check | [network/GATES.md](network/GATES.md) |
| Frontend | Màn hình web, form, trạng thái, accessibility | [frontend/GATES.md](frontend/GATES.md) |
| Mobile | App iOS/Android, offline, push, lưu trữ trên máy | [mobile/GATES.md](mobile/GATES.md) |

Một task thường mở 2–3 file. System Design mở trước khi các file còn lại, khi quyết định còn rẻ để đổi.

## Ngôn ngữ lập trình và bản đồ module

Mỗi file `GATES.md` ở trên đều mở đầu bằng **Bản đồ module và chiều phụ thuộc một chiều** (cho cả dựng khung dự án mới lẫn ánh xạ thư mục của dự án đã có). Đi kèm là thư mục [languages/](languages/README.md) khóa công cụ kiểm tra tĩnh, cách chia package/crate/project và các bẫy đặc thù theo từng ngôn ngữ:

- **Backend / Network / Worker:** [TypeScript](languages/typescript.md) · [Go](languages/go.md) · [Python](languages/python.md) · [Java & Kotlin](languages/jvm.md) · [Rust](languages/rust.md) · [C# / .NET](languages/csharp.md)
- **Frontend Web:** [TypeScript](languages/typescript.md)
- **Mobile:** [Swift (iOS) & Dart (Flutter)](languages/mobile-swift-dart.md) · [Kotlin (Android / KMP)](languages/jvm.md) · [TypeScript (React Native / Expo)](languages/typescript.md)
- **Database & Hợp đồng biên:** [SQL Engines (PostgreSQL, MySQL, SQLite, Redis) & IDL (OpenAPI, Protobuf, GraphQL)](languages/sql-idl.md)

## Vì sao bộ này

Trên GitHub, các harness làm phần mềm lặp lại cùng một hình: hợp đồng viết trước code, ràng buộc kiểm được, lượt thứ hai không tin lời người viết, và một chỗ ghi lỗi đã xảy ra. Công thức được giữ từ skill harness của GitHub:

```text
Harness = Instructions + Constraints + Feedback + Memory + Evaluation + Governance
```

Phần domain được viết lại từ các checklist công khai (mobile offline, backend production, database online-DDL, system design, resilience mạng). Máy orchestration đa agent, catalogue gắn một framework, và kịch bản phỏng vấn system design được để ngoài bộ này. Chi tiết nguồn và phần giữ lại nằm ở [sources.md](sources.md).
