# Design note

- Change brief:
- Domain liên quan:

## Bối cảnh

Ai dùng, tải dự kiến, dữ liệu có được mất không, độ trễ mục tiêu.

## Quyết định

| Câu hỏi | Chọn | Vì sao |
| --- | --- | --- |
| Consistency (mạnh / eventual / theo entity) | | |
| Nguồn sự thật | | |
| Cách hỏng khi dependency chết | | |
| Idempotency của ghi | | |
| Offline (mobile) hoặc trạng thái lỗi (web) | | |

## Hợp đồng

API, sự kiện, hoặc trạng thái UI. Gồm method, status, mã lỗi, và một ví dụ.

## Cách hỏng

1. Dependency chậm hoặc chết thì người dùng thấy gì?
2. Gửi lại sau timeout có tạo bản ghi thứ hai không?
3. Hai phiên bản app hoặc hai device cùng sửa một bản ghi thì sao?

## Cố ý chưa làm

Việc để sau, và tín hiệu nào sẽ khiến phải làm (QPS, dung lượng, số tenant, SLA).
