# Installer nhầm file cùng tên là file do Harness sở hữu

- Ngày: 2026-11-23
- Project: `hunguet123/Harness`
- Mức: rủi ro mất dữ liệu người dùng và bảo vệ giả

## Tóm tắt

Installer từng ghi đè/xóa Claude skill cùng tên của người dùng, giữ hook registration trỏ tới script đã bị gỡ, và báo `--check` thành công khi guard chưa được đăng ký.

## Nguyên nhân

Ownership được suy ra từ tên/đường dẫn thay vì marker hoặc manifest. `--check` kiểm file mẫu ở `harness/` thay vì trạng thái runtime tại `.cursor/hooks.json`.

## Phát hiện

`tests/install_test.sh` phải kiểm:

- existing hook được giữ và registration Harness được merge;
- file Claude cùng tên không bị ghi đè/xóa;
- `--local` không sửa file tracked;
- check fail khi registration guard bị xóa;
- uninstall không để registration mồ côi;
- `PROJECT.md` và language rules không drift.

## Bằng chứng

- Review reproduction ngày 2026-11-23.
- Regression suite: `tests/install_test.sh`.
