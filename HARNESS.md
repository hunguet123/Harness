# Hợp đồng harness

Một thay đổi chỉ xong khi bốn cổng dưới đây có bằng chứng. Người viết và người soát có thể là cùng một người, làm ở hai lượt: lượt hai chạy lại lệnh và đọc diff, không dựa vào trí nhớ lượt một.

## Sáu thành phần

| Thành phần | Trong bộ này | Việc của nó |
| --- | --- | --- |
| Instructions | `HARNESS.md`, `.cursor/skills/` | Quy trình G0–G3 và lúc nào mở domain nào |
| Constraints | `*/GATES.md`, `.cursor/rules/` | Cổng đầy đủ và bản ngắn agent mang theo |
| Feedback | Lệnh của project đích, `EXPLAIN`, MCP khi catalog cho phép | Cho kết quả chạy được |
| Memory | `templates/failure-memory.md` | Biến lỗi đã gặp thành kiểm tra lần sau |
| Evaluation | Cột bằng chứng trong brief | Chấm xong hay chưa bằng chứng, không bằng cảm giác |
| Governance | Cổng G0–G3 | Ai được đánh dấu xong, và khi nào phải dừng |

## Bốn cổng

### G0 — Phạm vi

Điền change brief.

- Hành vi người dùng hoặc hệ thống thấy được, viết một câu.
- Trong phạm vi và ngoài phạm vi.
- Domain bị đụng: đánh dấu đúng file `GATES.md` sẽ mở.
- Tiêu chí chấp nhận: quan sát được, kiểm được.

Thiếu G0 thì chưa viết code sản phẩm. Sửa typo, đổi tên nội bộ, hoặc format thì ghi một dòng "ngoài cổng domain" và chạy lint/test của project.

### G1 — Thiết kế

Bắt buộc khi thay đổi đụng một trong các ranh giới:

- Hợp đồng API hoặc sự kiện
- Schema hoặc migration
- Hợp đồng UI (vai trò, tên accessible, trạng thái màn hình)
- Giao thức mạng: timeout, retry, idempotency
- Tư thế offline của mobile

Dùng [templates/design-note.md](templates/design-note.md). Ghi quyết định và cách hỏng. Cổng domain tương ứng là danh sách câu hỏi của G1.

### G2 — Làm và kiểm

- Mỗi hành vi mới có test hoặc một kiểm tra thủ công được ghi lệnh và kết quả.
- Ràng buộc nằm ở nơi nền tảng cưỡng bức được: constraint DB, validation DTO, type, lint, unique key, timeout trong client.
- Diff chỉ chứa phần thuộc phạm vi G0.
- Lệnh kiểm chứng là lệnh của project đích, ghi trong brief: unit, integration hoặc end-to-end, lint, build. Harness không chọn package manager hay framework.

### G3 — Soát và ghi nhớ

Lượt hai:

- Chạy lại lệnh đã khai trong brief. Dán pass/fail.
- Đối chiếu diff với cổng domain. Mục bỏ qua có lý do.
- Lỗi review hoặc lỗi chạy có thể tái diễn: viết failure memory, gồm mục **Phát hiện** (test, lint, hoặc bước review sẽ bắt lần sau).

## Mức chặn

| Mức | Ý nghĩa |
| --- | --- |
| BLOCK | Chưa có bằng chứng thì không đánh dấu xong |
| DECIDE | Phải ghi một quyết định. Im lặng là chưa xong |

## Bằng chứng hợp lệ

Một trong các dạng sau, gắn với đúng mục cổng:

- Lệnh của project đích và kết quả: unit, integration hoặc end-to-end, lint, build
- Truy vấn và plan: câu SQL kèm `EXPLAIN` cho đường nóng
- Hợp đồng: method, status, mã lỗi, ví dụ payload
- Quyết định viết trong design note: consistency, offline posture, chiến lược conflict, ngân sách timeout
- Với kiểm tra thủ công: các bước, dữ liệu vào, kết quả nhìn thấy

Ảnh chụp giao diện một mình không phải bằng chứng hành vi.

## Định nghĩa xong

- G0 có brief.
- Mỗi domain bị đụng đã tick BLOCK, hoặc ghi "không áp dụng" kèm lý do.
- G2 có lệnh đã chạy.
- G3 đã đối chiếu diff.
- Failure memory được viết khi có lỗi đáng lặp, hoặc brief ghi "không có lỗi đáng ghi".

## Việc harness không làm

Harness không thay đặc tả sản phẩm và không sinh code. Khi project đích đã có lint, test, hoặc quy ước chặt hơn file này, làm theo quy ước đó và ghi lệch trong brief.
