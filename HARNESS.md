# Hợp đồng harness

Một thay đổi chỉ xong khi bốn cổng dưới đây có bằng chứng. Người viết và người soát có thể là cùng một người, làm ở hai lượt: lượt hai chạy lại lệnh và đọc diff, không dựa vào trí nhớ lượt một.

## Sáu thành phần

| Thành phần | Trong bộ này | Việc của nó |
| --- | --- | --- |
| Instructions | `HARNESS.md`, `AGENTS.md`, `.cursor/skills/` | Quy trình G0–G3, khảo sát dự án (`onboard-project`) và định tuyến domain |
| Constraints | `*/GATES.md`, `languages/*.md`, `.cursor/rules/`, `.cursor/hooks/` | Cổng hành vi, bản đồ module, hồ sơ ngôn ngữ và hook chặn cơ học |
| Feedback | Lệnh của project đích trong `PROJECT.md`, `EXPLAIN`, MCP khi catalog cho phép | Cho kết quả chạy được |
| Memory | `PROJECT.md`, `templates/failure-memory.md` | Nhớ cấu trúc/lệnh của repo đích và biến lỗi đã gặp thành kiểm tra lần sau |
| Evaluation | Cột bằng chứng trong brief, ví dụ chuẩn `examples/order-create/` | Chấm xong hay chưa bằng chứng, không bằng cảm giác |
| Governance | Cổng G0–G3 và ranh giới Escalation | Ai được đánh dấu xong, và khi nào phải dừng hỏi |

## Bốn cổng

### G0 — Phạm vi

Đọc `PROJECT.md` của dự án đích (nếu mới gắn Harness lần đầu thì chạy skill `onboard-project` để điền `PROJECT.md` từ [templates/project-profile.md](templates/project-profile.md)). Copy [templates/change-brief.md](templates/change-brief.md) sang bản ghi của task ở project đích (ví dụ `docs/changes/<ten-task>/change-brief.md`, xem mẫu đã điền tại [examples/order-create/change-brief.md](examples/order-create/change-brief.md)), rồi điền. Không ghi đè các file mẫu trong `templates/`.

- Hành vi người dùng hoặc hệ thống thấy được, viết một câu.
- Trong phạm vi và ngoài phạm vi.
- Domain, module bị đụng, và hồ sơ ngôn ngữ: đánh dấu đúng file `GATES.md` và `languages/*.md` sẽ mở (xem [languages/README.md](languages/README.md)).
- Tiêu chí chấp nhận: quan sát được, kiểm được.

Thiếu G0 thì chưa viết code sản phẩm. Sửa typo, đổi tên nội bộ, hoặc format thì ghi một dòng "ngoài cổng domain" và chạy lint/test của project.

### G1 — Thiết kế

Bắt buộc khi thay đổi đụng một trong các ranh giới:

- Hợp đồng API hoặc sự kiện
- Schema hoặc migration
- Hợp đồng UI (vai trò, tên accessible, trạng thái màn hình)
- Giao thức mạng: timeout, retry, idempotency
- Tư thế offline của mobile
- Cạnh phụ thuộc module mới hoặc đổi chiều phụ thuộc hiện có

Copy [templates/design-note.md](templates/design-note.md) sang cạnh change brief trước khi viết code. Ghi quyết định (tín hiệu, chọn, đánh đổi & cách hỏng, đổi khi nào) và hợp đồng biên. Cổng domain tương ứng là danh sách câu hỏi của G1.

### G2 — Làm và kiểm

- Mỗi hành vi mới có test hoặc một kiểm tra thủ công được ghi lệnh và kết quả.
- Ràng buộc nằm ở nơi nền tảng cưỡng bức được: constraint DB, validation DTO, type, lint, unique key, timeout trong client.
- Diff chỉ chứa phần thuộc phạm vi G0.
- Lệnh kiểm chứng là lệnh của project đích, ghi trong brief: unit, integration hoặc end-to-end, lint, build. Harness không chọn package manager hay framework.
- Nếu phạm vi G0 chỉ dừng ở thiết kế (chưa đổi code thực thi), ghi `K/A — chỉ thiết kế, bằng chứng ở design note` ở G2.

### G3 — Soát và ghi nhớ

Lượt hai:

- Chạy lại lệnh đã khai trong brief. Dán pass/fail.
- Đối chiếu diff với cổng domain. Ghi kết quả từng mục BLOCK/DECIDE áp dụng vào bảng **Đối chiếu cổng áp dụng** của brief; có thể gộp các mục không áp dụng cùng section khi dùng chung một lý do. `GATES.md` là tài liệu chuẩn chỉ đọc, không phải nơi tick cho task.
- Lỗi review hoặc lỗi chạy có thể tái diễn: copy [templates/failure-memory.md](templates/failure-memory.md) sang nơi lưu lỗi của project đích, gồm mục **Phát hiện** (test, lint, hoặc bước review sẽ bắt lần sau).

## Mức chặn

| Mức | Ý nghĩa |
| --- | --- |
| BLOCK | Chưa có bằng chứng thì không đánh dấu xong |
| DECIDE | Phải ghi một quyết định. Im lặng là chưa xong |

Trong `GATES.md`, các mục BLOCK được tách theo hai phạm vi áp dụng để PR nhỏ không phải giải trình toàn bộ hạ tầng:

- **Theo từng thay đổi:** áp cho mọi task mở domain đó.
- **Chuẩn nền service:** BLOCK khi dựng mới service, tạo client/pool mới, thêm dependency ngoài, hoặc sửa bootstrap/vận hành. Khi sửa nghiệp vụ trên nền có sẵn mà không đụng các phần này, ghi nhận một lần ở brief thay vì giải trình từng dòng (nếu phát hiện nền hiện tại đang thiếu mục chuẩn nền liên quan trực tiếp tới đường vừa sửa thì phải nêu rủi ro trong brief).

## Bằng chứng hợp lệ

Một trong các dạng sau, gắn với đúng mục cổng:

- Lệnh của project đích và kết quả: unit, integration hoặc end-to-end, lint, build
- Truy vấn và plan: câu SQL kèm `EXPLAIN` cho đường nóng
- Hợp đồng: method, status, mã lỗi, ví dụ payload
- Quyết định viết trong design note: consistency, offline posture, chiến lược conflict, ngân sách timeout
- Với kiểm tra thủ công: các bước, dữ liệu vào, kết quả nhìn thấy

Ảnh chụp giao diện một mình không phải bằng chứng hành vi.

## Định nghĩa xong

- G0 có brief (bản riêng của task, không sửa file trong `templates/`).
- Mỗi mục BLOCK/DECIDE áp dụng của domain bị đụng đã có dòng PASS/N/A và bằng chứng hoặc lý do trong brief.
- G2 có lệnh đã chạy, hoặc ghi `K/A` kèm lý do khi phạm vi chỉ là thiết kế.
- G3 đã đối chiếu diff (hoặc design note nếu chưa có code).
- Failure memory được viết khi có lỗi đáng lặp, hoặc brief ghi "không có lỗi đáng ghi".

## Việc harness không làm

Harness không thay đặc tả sản phẩm và không sinh code. Khi project đích đã có lint, test, hoặc quy ước chặt hơn file này, làm theo quy ước đó và ghi lệch trong brief.
