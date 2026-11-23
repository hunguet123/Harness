# Change brief

- Ngày:
- Project:
- Stack (ngôn ngữ, framework, database):
- Một câu hành vi:

## Phạm vi

- Trong phạm vi:
- Ngoài phạm vi:
- Loại thay đổi:
  - [ ] Sửa/thêm nghiệp vụ trên nền có sẵn (kiểm mục **Theo từng thay đổi**; chuẩn nền giữ nguyên)
  - [ ] Dựng mới service / thêm client hoặc dependency ngoài / sửa bootstrap-vận hành (kiểm cả **Chuẩn nền service**)

## Domain

Đánh dấu file sẽ mở (đường dẫn tính từ gốc bộ harness):

- [ ] System Design — `system-design/GATES.md`
- [ ] Backend — `backend/GATES.md`
- [ ] Database — `database/GATES.md`
- [ ] Network — `network/GATES.md`
- [ ] Frontend — `frontend/GATES.md`
- [ ] Mobile — `mobile/GATES.md`

Mục không áp dụng (một dòng lý do mỗi mục):

## Tiêu chí chấp nhận

1.
2.

## Ranh giới

Có đụng API, schema, hợp đồng UI, timeout/retry, hoặc offline không?

- [ ] Có — link design note:
- [ ] Không

## Bằng chứng G2

Điền lệnh thật của project đích. Nếu mục không áp dụng (ví dụ phạm vi chỉ là thiết kế, chưa đổi code thực thi), ghi `K/A — lý do`.

| Việc | Lệnh | Kết quả |
| --- | --- | --- |
| Unit | | |
| Integration hoặc end-to-end | | |
| Lint | | |
| Build | | |

Lệnh khác (EXPLAIN, kiểm tra tay):

## G3

- [ ] Đã chạy lại lệnh ở lượt hai
- [ ] Diff khớp phạm vi
- [ ] Cổng domain đã tick hoặc có lý do bỏ qua
- [ ] Failure memory: link, hoặc "không có lỗi đáng ghi"
