---
name: harness-mcp
description: >-
  Chooses and limits MCP servers for harness evidence. Use when a task needs
  a live browser, database schema, EXPLAIN, or an MCP server, or when the user
  mentions MCP, Chrome DevTools, or Postgres MCP. Do not enable servers by
  default and do not use archived MCP reference servers.
---

# MCP

Đọc [catalog.md](../../../mcp/catalog.md) rồi mới sửa `.cursor/mcp.json`.

Nguồn danh sách: [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers). Postgres và GitHub trong repo archive không được thêm.

## Chọn

| Cần | Server | Không làm |
| --- | --- | --- |
| Click trang, log mạng, trace | `chrome-devtools` trong `mcp.example.json` | Không dùng profile Chrome đang đăng nhập thật |
| Schema hoặc `EXPLAIN` Postgres | `@microsoft/postgres-mcp`, profile read-only | Không dán URI vào json |
| Engine khác | DBHub với `readonly` | Không bật ghi |
| Nhớ lỗi lần sau | File `templates/failure-memory.md` | Không dùng server Memory làm chỗ ghi harness |

Chỉ copy khối server task cần từ [mcp.example.json](../../../mcp/mcp.example.json) vào `.cursor/mcp.json`. Hết task thì trả file về `{"mcpServers": {}}` nếu server không còn thuộc project đích (đặc biệt khi `.cursor` đang được symlink ở thư mục cha nhiều project).

Kết quả tool ghi vào change brief: gọi gì, và kết quả rút gọn.
