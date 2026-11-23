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

- Đặt tài liệu và cổng vào `harness/`, nạp rule (`harness-*.mdc`) và 9 skill vào `.cursor/` của dự án đích mà **không ghi đè** `README.md`, `.cursor/mcp.json` hiện có, hay các rule/skill riêng của dự án.
- **Dùng cá nhân trên repo chung của team (không làm bẩn `git status`):** thêm `--local` để tự ghi đường dẫn vào `.git/info/exclude`:
  ```sh
  curl -fsSL https://raw.githubusercontent.com/hunguet123/Harness/main/install.sh | sh -s -- --local
  ```
- **Kiểm tra hoặc gỡ bỏ:**
  ```sh
  /duong/dan/harness/install.sh --check /duong/dan/project
  /duong/dan/harness/install.sh --uninstall /duong/dan/project
  ```

## Dùng trong 5 phút

1. Đọc [HARNESS.md](HARNESS.md) — hợp đồng: công thức, bốn cổng, thế nào là bằng chứng.
2. Copy [templates/change-brief.md](templates/change-brief.md) sang ghi chú task ở project đích (ví dụ `docs/changes/<ten-task>/change-brief.md`). Điền phạm vi và domain bị đụng. Không sửa trực tiếp các file mẫu trong `templates/`.
3. Mở file `GATES.md` của từng domain bị đụng. Tick mục áp dụng. Mục không áp dụng thì ghi lý do một dòng.
4. Chạy kiểm tra và dán kết quả vào brief. Thiếu bằng chứng thì chưa xong.
5. Lỗi có thể lặp lại: copy [templates/failure-memory.md](templates/failure-memory.md) sang nơi lưu lỗi của project đích, ghi nguyên nhân và kiểm tra sẽ chặn lần sau.

Thay đổi đụng ranh giới (API, schema, hợp đồng UI, giao thức mạng, offline) thì copy [templates/design-note.md](templates/design-note.md) sang cạnh brief và điền trước khi viết code.

## Rule, skill, MCP

Ba lớp này nằm trong `.cursor/` của harness, theo cách GitHub đóng gói cho Cursor: rule ngắn trong `.cursor/rules/*.mdc`, skill trong `.cursor/skills/*/SKILL.md`, MCP trong `.cursor/mcp.json`. Nội dung được rút từ các skill công khai, rồi trỏ về `GATES.md` thay vì chép nguyên checklist.

| Lớp | Vai trò | File |
| --- | --- | --- |
| Rule | Ràng buộc ngắn, agent tự chọn theo mô tả | [.cursor/rules](.cursor/rules) |
| Skill | Quy trình: chạy, soát, và từng domain | [.cursor/skills](.cursor/skills) |
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

## Vì sao bộ này

Trên GitHub, các harness làm phần mềm lặp lại cùng một hình: hợp đồng viết trước code, ràng buộc kiểm được, lượt thứ hai không tin lời người viết, và một chỗ ghi lỗi đã xảy ra. Công thức được giữ từ skill harness của GitHub:

```text
Harness = Instructions + Constraints + Feedback + Memory + Evaluation + Governance
```

Phần domain được viết lại từ các checklist công khai (mobile offline, backend production, database online-DDL, system design, resilience mạng). Máy orchestration đa agent, catalogue gắn một framework, và kịch bản phỏng vấn system design được để ngoài bộ này. Chi tiết nguồn và phần giữ lại nằm ở [sources.md](sources.md).
