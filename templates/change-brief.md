# Change brief

- Ngày:
- Project:
- Stack (ngôn ngữ, framework, database):
- Hồ sơ ngôn ngữ mở (`languages/*.md`):
- Module bị đụng (theo bản đồ trong `GATES.md`):
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

Có đụng API, schema, hợp đồng UI, timeout/retry, offline, hoặc thêm cạnh phụ thuộc module mới không?

- [ ] Có — link design note:
- [ ] Không

## Đối chiếu cổng áp dụng

Không sửa `GATES.md`. Ghi một dòng cho mỗi mục BLOCK/DECIDE áp dụng; các mục không áp dụng trong cùng một section có thể gộp một dòng nếu cùng lý do.

| File / section | Mục BLOCK hoặc DECIDE | Kết quả | Bằng chứng hoặc lý do không áp dụng |
| --- | --- | --- | --- |
| | | PASS / N/A | |

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
- [ ] Diff khớp phạm vi và không vi phạm chiều phụ thuộc module
- [ ] Mỗi mục BLOCK/DECIDE áp dụng đã có dòng PASS/N/A và bằng chứng/lý do trong brief
- [ ] Failure memory: link, hoặc "không có lỗi đáng ghi"
