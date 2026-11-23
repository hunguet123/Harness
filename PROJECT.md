# Hồ sơ dự án — Harness

- Dự án: `hunguet123/Harness`
- Ngày cập nhật: 2026-11-23
- Ngôn ngữ & framework chính: POSIX shell, Markdown, JSON
- Cơ sở dữ liệu & hạ tầng phụ: Không có; GitHub phân phối `install.sh`

## 1. Lệnh kiểm chứng chuẩn của dự án (G2 Sensors)

- Kiểm cú pháp: `sh -n install.sh hooks/harness-guard.sh tests/install_test.sh`
- Linter: `git diff --check`
- Integration: `./tests/install_test.sh`
- Kiểm toàn vẹn: `./install.sh --check .`
- Build: `K/A — bộ tài liệu và shell script không có bước build`

## 2. Ánh xạ thư mục vào Bản đồ Module

- Entrypoint / Bootstrap: `install.sh`
- Biên giao tiếp: tùy chọn CLI của `install.sh`, `.cursor/hooks.json`
- Điều phối nghiệp vụ: các hàm install/check/uninstall trong `install.sh`
- Lõi nghiệp vụ thuần: quy tắc G0–G3 trong `HARNESS.md`
- Lưu trữ: file được cài vào `harness/`, `.cursor/`, `.claude/` và block đánh dấu
- Tích hợp: GitHub archive/git clone, Cursor hooks

## 3. Ranh giới quyền hạn của Agent

- Không ghi đè hoặc xóa file người dùng nếu không có dấu ownership của Harness.
- Thay đổi định dạng cấu hình hooks hoặc ownership metadata phải có design note và regression test.
- Không push nếu review còn BLOCK hoặc DECIDE.

## 4. Bẫy lịch sử cần tránh

1. “File đã được copy” không đồng nghĩa hook đã được đăng ký trong `hooks.json`.
2. Tên skill trùng không chứng minh Harness sở hữu file; uninstall phải dựa trên manifest/marker.
3. `--local` không được sửa bất kỳ file tracked nào.
