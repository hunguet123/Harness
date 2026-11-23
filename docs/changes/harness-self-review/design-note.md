# Design note — Ownership an toàn cho installer

- Change brief: [change-brief.md](change-brief.md)
- Domain liên quan: Harness developer tooling
- Ngôn ngữ: POSIX shell, JSON

## Bối cảnh

Installer chạy trên dự án mới và cũ, nơi `.cursor/hooks.json`, `.claude/skills/` và các file Markdown có thể đã thuộc người dùng. Sai ownership có thể phá dữ liệu hoặc tạo cảm giác bảo vệ giả.

## Ánh xạ module và ranh giới

- `install.sh`: duy nhất được tạo/cập nhật/gỡ artifact.
- `hooks/hooks.example.json`: cấu hình registration chuẩn, không phải cấu hình đích.
- `.cursor/harness-install-manifest`: ghi chính xác artifact do Harness tạo, không chứa secret.
- `tests/install_test.sh`: cảm biến lifecycle và preservation.

## Quyết định

| Hạng mục / Tín hiệu | Chọn | Đánh đổi & cách hỏng | Đổi khi nào |
| --- | --- | --- | --- |
| Hook config | Merge/remove đúng registration Harness bằng JSON parser | Cần `python3` để sửa JSON an toàn; nếu thiếu thì dừng rõ ràng thay vì báo thành công giả | Khi Cursor cung cấp CLI quản lý hook |
| Claude support | Chỉ bật bằng `--claude` | Người dùng có `.claude/` vẫn phải chọn rõ; tránh ghi đè ngoài ý muốn | Khi có ownership API chính thức |
| Ownership | Manifest riêng ghi file tùy chọn do Harness tạo | Manifest mất thì uninstall bảo thủ, giữ file | Khi tất cả artifact hỗ trợ marker nội tại |
| Language update | PROJECT autogen được cập nhật cùng rule; PROJECT đã onboard giữ nguyên rule đã ghi | Repo đổi stack sau onboarding cần `--lang` rõ ràng | Khi profile lưu machine-readable metadata |
| Secret guard | Match URI, token prefix và key-name có value không rỗng | Heuristic có false positive; chỉ áp dụng cho staged MCP config | Khi có schema secret reference chuẩn |

## Hợp đồng CLI

- `--claude`: opt-in duy nhất cho `CLAUDE.md` và `.claude/skills/`.
- `--cursor-only`: không tạo/cập nhật `AGENTS.md` hay Claude artifact.
- `--local`: không sửa file tracked của dự án.
- `--check`: chỉ OK khi script guard tồn tại, executable và registrations Harness đang active.
- `--uninstall`: chỉ xóa artifact tùy chọn được manifest/marker chứng minh thuộc Harness.

## Cách hỏng

1. Không có `python3`: cài/kiểm tra hook dừng với thông báo dependency thay vì bỏ qua.
2. Config JSON hỏng: dừng trước khi sửa, giữ nguyên file.
3. Manifest mất: uninstall giữ file không xác định và chỉ xóa block có marker.

## Cố ý chưa làm

Không xây secret scanner tổng quát; guard chỉ là lớp chặn sớm cho `.cursor/mcp.json`, không thay thế secret scanning trong CI.
