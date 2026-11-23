# Change brief — Khép các BLOCK từ self-review Harness

- Ngày: 2026-11-23
- Project: `hunguet123/Harness`
- Stack: POSIX shell, Markdown, JSON
- Hồ sơ ngôn ngữ mở: `languages/README.md` (shell chưa có profile riêng)
- Module bị đụng: installer lifecycle, Cursor hooks, Claude adapter, tài liệu governance
- Một câu hành vi: Cài, kiểm tra, cập nhật và gỡ Harness không được ghi đè/xóa file người dùng; trạng thái “OK” phải chứng minh guard thực sự được kích hoạt.

## Phạm vi

- Trong phạm vi: ownership manifest, merge/remove hook registrations, Claude opt-in, `--local`, language-profile sync, secret guard, regression tests và tài liệu nhất quán.
- Ngoài phạm vi: thêm domain, ngôn ngữ hay công cụ boundary scanner mới.
- Loại thay đổi:
  - [x] Sửa installer và hook trên nền có sẵn
  - [x] Sửa bootstrap/vận hành của bộ cài

## Domain

Thay đổi này là developer tooling của chính Harness, ngoài sáu domain sản phẩm. Áp dụng cổng chung G0–G3 và hợp đồng POSIX shell trong `PROJECT.md`.

## Tiêu chí chấp nhận

1. Existing `hooks.json` được merge mà không mất hook người dùng; `--check` fail nếu registration thiếu hoặc sai.
2. Claude chỉ được cài khi có `--claude`; file trùng tên không bị ghi đè/xóa nếu Harness không sở hữu.
3. `--local` giữ `git status` sạch với mọi file tracked.
4. Reinstall giữ language rules và `PROJECT.md` đồng bộ; uninstall không để hook trỏ tới script đã xóa.
5. Guard chặn URI/token/API-key phổ biến trong staged `.cursor/mcp.json`.

## Ranh giới

- [x] Có — [design-note.md](design-note.md)

## Đối chiếu cổng áp dụng

| File / section | Mục BLOCK hoặc DECIDE | Kết quả | Bằng chứng hoặc lý do không áp dụng |
| --- | --- | --- | --- |
| `HARNESS.md` / G0 | Phạm vi, tiêu chí chấp nhận và stack được ghi trước sửa | PASS | Brief này và `PROJECT.md` |
| `HARNESS.md` / G1 | Thay đổi ownership/hook lifecycle có quyết định trước code | PASS | [design-note.md](design-note.md) |
| `PROJECT.md` / Ownership | Không ghi đè/xóa file không có ownership | PASS | Manifest + preflight; regression suite kiểm collision/symlink/non-file/uninstall |
| `PROJECT.md` / `--local` | Không sửa file tracked | PASS | Regression suite kiểm tracked hooks, Claude, team Harness và team skill |
| Hook runtime | Registration active; staged MCP secret bị chặn bằng JSON hợp lệ | PASS | `--check` + test URI/token/API-key, nested worktree và lệnh `git -C` |
| Legacy migration | Chỉ adopt đường dẫn lịch sử khi có xác nhận rõ | PASS | `--adopt-legacy` + test rollback/conflict |

## Bằng chứng G2

| Việc | Lệnh | Kết quả |
| --- | --- | --- |
| Syntax | `sh -n install.sh hooks/harness-guard.sh tests/install_test.sh` | PASS |
| Integration | `./tests/install_test.sh` | PASS (7/7) |
| Diff | `git diff --check` | PASS |
| Integrity | `./install.sh --check .` | PASS |
| Build | K/A | Shell/tài liệu không có build |

## G3

- [x] Đã chạy lại lệnh ở lượt hai
- [x] Diff khớp phạm vi
- [x] Không còn BLOCK/DECIDE (review đối lập cuối: No BLOCK/DECIDE)
- [x] Failure memory: [failure-memory.md](failure-memory.md)
