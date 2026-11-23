# MCP trong harness

MCP là công cụ lấy bằng chứng, không phải cổng kiểm tra. Cổng nằm ở `GATES.md`. File `.cursor/mcp.json` giao kèm có `mcpServers` rỗng: mở harness không tự chạy server và không chứa bí mật.

Định dạng file theo [Cursor MCP](https://cursor.com/docs/mcp): server stdio cần `type`, `command`, `args`. Biến môi trường viết `${env:NAME}`, không dán giá trị thật.

## Luật chọn server

Lấy từ [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers).

| Nhóm | Server | Dùng trong harness |
| --- | --- | --- |
| Reference, còn duy trì | Fetch, Filesystem, Git, Memory, Sequential Thinking, Time | Không bật sẵn. Git và filesystem trùng việc shell của agent. Memory MCP là đồ thị tri thức, không thay `templates/failure-memory.md`. Fetch đọc trang công khai; server này từ chối IP nội bộ trừ khi bị tắt guard. |
| Reference, đã archive | GitHub, PostgreSQL (`@modelcontextprotocol/server-postgres`) | Không dùng. Repo archive ghi rõ không còn bảo trì và không có bảo đảm an ninh. |
| Thay Postgres còn duy trì | [`@microsoft/postgres-mcp`](https://github.com/microsoft/postgres-mcp) | Bật khi cần schema hoặc `EXPLAIN` trên Postgres thật. Profile read-only, mật khẩu ở keyring. |
| Thay Postgres đa engine | [`@bytebase/dbhub`](https://github.com/bytebase/dbhub) | Chỉ khi cần engine khác Postgres. Bật `readonly`. Không đưa DSN vào file commit. |
| Browser cho agent | [`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp) | Bật khi cổng frontend cần log mạng, console, hoặc trace hiệu năng. Chrome stable và Node LTS. |

## Theo domain

| Domain | Server | Khi nào copy vào `.cursor/mcp.json` |
| --- | --- | --- |
| Frontend | `chrome-devtools` | Cần thao tác trang thật, xem request, hoặc trace. Ảnh một mình không đủ. |
| Database | `postgres` | Cần plan trên database thật. Test cục bộ không có `EXPLAIN` đủ. |
| Backend, network, mobile, system design | Không | Bằng chứng là test, thiết kế, và lệnh của project đích. |

Copy một khối từ [mcp.example.json](mcp.example.json) khi task cần, và trả `.cursor/mcp.json` về `{"mcpServers": {}}` ngay khi hết task (đặc biệt khi `.cursor` đang được symlink ở thư mục cha chứa nhiều project). Đừng dán cả file nếu task chỉ cần một server; nếu ghim server lâu dài cho một repo riêng thì thay `@latest` bằng phiên bản đã kiểm.

## Bật Postgres

```sh
npx -y @microsoft/postgres-mcp connection add local \
  "postgresql://USER@HOST:5432/DB"
npx -y @microsoft/postgres-mcp connection set-password local
```

Đặt profile ở chế độ chỉ đọc trước khi agent gọi tool. `mcp.json` chỉ chứa lệnh `run`, không chứa URI.

## Bật Chrome DevTools

Khối `chrome-devtools` trong file ví dụ là cấu hình chuẩn của repo ChromeDevTools. Server tự mở Chrome khi có lệnh tool. Không dùng profile đang đăng nhập tài khoản thật: server đọc được nội dung trình duyệt.
