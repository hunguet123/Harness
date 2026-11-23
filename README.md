# Harness làm phần mềm

Bộ chuẩn để bắt đầu, làm, và kết thúc một thay đổi trong sáu mảng: Mobile, Frontend, Backend, System Design, Database, Network.

Thư mục này là một bộ độc lập. Nó không lấy stack, script, hay quy ước từ thư mục nào khác. Mỗi task tự ghi ngôn ngữ, framework, database, và lệnh kiểm tra vào change brief.

## Dùng trong 5 phút

1. Đọc [HARNESS.md](HARNESS.md) — hợp đồng: công thức, bốn cổng, thế nào là bằng chứng.
2. Copy [templates/change-brief.md](templates/change-brief.md) vào ghi chú task. Điền phạm vi và domain bị đụng.
3. Mở file `GATES.md` của từng domain bị đụng. Tick mục áp dụng. Mục không áp dụng thì ghi lý do một dòng.
4. Chạy kiểm tra và dán kết quả vào brief. Thiếu bằng chứng thì chưa xong.
5. Lỗi có thể lặp lại: copy [templates/failure-memory.md](templates/failure-memory.md), ghi nguyên nhân và kiểm tra sẽ chặn lần sau.

Thay đổi đụng ranh giới (API, schema, hợp đồng UI, giao thức mạng) thì thêm [templates/design-note.md](templates/design-note.md) trước khi viết code.

## Rule, skill, MCP

Ba lớp này nằm trong `.cursor/` của harness, theo cách GitHub đóng gói cho Cursor: rule ngắn trong `.cursor/rules/*.mdc`, skill trong `.cursor/skills/*/SKILL.md`, MCP trong `.cursor/mcp.json`. Nội dung được rút từ các skill công khai, rồi trỏ về `GATES.md` thay vì chép nguyên checklist.

| Lớp | Vai trò | File |
| --- | --- | --- |
| Rule | Ràng buộc ngắn, agent tự chọn theo mô tả | [.cursor/rules](.cursor/rules) |
| Skill | Quy trình: chạy, soát, và từng domain | [.cursor/skills](.cursor/skills) |
| MCP | Server tùy chọn để lấy bằng chứng | [mcp/catalog.md](mcp/catalog.md) |

`mcp.json` để trống. Server còn duy trì (Chrome DevTools, Postgres read-only) chỉ được copy từ [mcp/mcp.example.json](mcp/mcp.example.json) khi task cần. Server archive như `@modelcontextprotocol/server-postgres` không dùng.

Cursor nạp `.cursor` ở gốc workspace. Thư mục cha có symlink `.cursor` trỏ vào đây để agent thấy rule và skill. Nội dung vẫn chỉ sống trong harness.

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
