# Design note

- Change brief:
- Domain liên quan:
- Ngôn ngữ & hồ sơ áp dụng (`languages/*.md`):

## Bối cảnh

Ai dùng, tải dự kiến, dữ liệu có được mất không, độ trễ mục tiêu.

## Ánh xạ module và ranh giới

Ánh xạ thư mục thực tế của dự án vào bản đồ module trong `GATES.md` (chiều import hợp lệ, cạnh nào cấm đi xuyên):

- Module thay đổi:
- Chiều phụ thuộc giữ nguyên / thêm mới:

## Quyết định

| Hạng mục / Tín hiệu | Chọn | Đánh đổi & cách hỏng | Đổi khi nào |
| --- | --- | --- | --- |
| Consistency (mạnh / eventual / theo phiên bản) | | | |
| Nguồn sự thật | | | |
| Idempotency của ghi | | | |
| Offline (mobile) hoặc trạng thái lỗi (web) | | | |
| Thành phần thêm mới (nếu có) | | | |

## Hợp đồng

API, sự kiện, hoặc trạng thái UI. Gồm method, status, mã lỗi, và một ví dụ.

## Cách hỏng

1. Dependency chậm hoặc chết thì người dùng thấy gì?
2. Gửi lại sau timeout có tạo bản ghi thứ hai không?
3. Hai phiên bản app hoặc hai device cùng sửa một bản ghi thì sao?

## Cố ý chưa làm

Việc để sau, và tín hiệu nào sẽ khiến phải làm (QPS, dung lượng, số tenant, SLA).
