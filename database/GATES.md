# Database

Mở khi thêm hoặc đổi bảng, cột, khóa, index, transaction, hoặc truy vấn trên đường nóng. Invariant và test đọc lại áp dụng với mọi engine. Mục DDL online là BLOCK khi bảng đã có traffic trên engine giữ khóa (mẫu dưới đây là Postgres).

Nguồn tinh chỉnh: [sota-databases](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-databases/SKILL.md), [engineering-playbook database-review](https://github.com/sigmadigitalza/engineering-playbook/blob/main/docs/playbooks/database-review.md), [DATABASE_CHECKLIST](https://github.com/baelfyre/orchestra/blob/main/skills/chronicler/DATABASE_CHECKLIST.md).

## Bản đồ module dữ liệu và ngôn ngữ

Tầng dữ liệu được quản lý tách bạch qua 5 module:

- `schema-constraints`: định nghĩa bảng, kiểu dữ liệu chính xác (`timestamptz`, `numeric`/số nguyên đơn vị nhỏ nhất cho tiền), khóa chính/ngoại, `UNIQUE`, `CHECK`, `NOT NULL`, và cột/chính sách cô lập `tenant`.
- `migrations`: chuỗi phiên bản DDL một chiều, tách riêng pha mở rộng (`expand`), lấp dữ liệu nền theo lô (`backfill`), và thu hẹp/siết ràng buộc (`contract`).
- `queries-indexes`: tập câu đọc/ghi đã đặt tên (`sqlc`, query builder hoặc repository), index ghép/từng phần gắn với truy vấn thật, phân trang keyset và bằng chứng `EXPLAIN`.
- `tx-concurrency`: quản lý phiên/unit-of-work gắn với use case, khóa lạc quan (`version`) hoặc khóa bi quan (`FOR UPDATE`), chính sách thử lại có trần khi deadlock/serialization.
- `outbox-lifecycle`: bảng `outbox` (phát sự kiện sau commit), `inbox` (chống xử lý trùng), bảng lưu vết (`audit`), phân vùng (`partition`) và dọn dữ liệu hết hạn (`retention`).

**Hồ sơ engine & ngôn ngữ truy vấn:** bắt buộc đọc thêm [SQL Engines & IDL](../languages/sql-idl.md) để áp đúng luật riêng của **PostgreSQL**, **MySQL/InnoDB**, **SQLite**, **Redis**, kèm hồ sơ ngôn ngữ Backend đang giữ ORM/driver ([Go](../languages/go.md), [TypeScript](../languages/typescript.md), [Python](../languages/python.md), [Java/Kotlin](../languages/jvm.md), [Rust](../languages/rust.md), [C#](../languages/csharp.md)).

## G1 — Invariant nằm trong schema

BLOCK

- [ ] Mỗi luật "không bao giờ được sai" có chỗ cưỡng bức: primary key, foreign key, unique, check, hoặc not null. Luật chỉ nằm trong code ứng dụng được ghi lý do.
- [ ] Null, chuỗi rỗng, và field vắng mặt được phân biệt trong hợp đồng ghi.
- [ ] Unique phản ánh nghiệp vụ thật (kể cả unique từng phần, ví dụ chỉ với hàng còn hiệu lực).
- [ ] Xóa cha với con được khai báo: restrict, cascade, hoặc soft-delete. Cascade hàng loạt là quyết định viết trong design note.
- [ ] Multi-tenant: tenant nằm trong khóa, unique, và mọi câu đọc/ghi. Thiếu tenant trên bảng dùng chung là BLOCK.

DECIDE

- [ ] SQL hay kho khác. Chọn kho phi giao dịch thì ghi nghiệp vụ nào được phép mất ACID.
- [ ] Khóa chính: số tự tăng hay id có thứ tự thời gian. Ghi hệ quả index và lộ id.

## G1 — Truy vấn và index

BLOCK

- [ ] Mỗi truy vấn trên đường nóng nêu index sẽ dùng, hoặc giải thích vì sao sequential scan vẫn đúng (bảng nhỏ hoặc dữ liệu cục bộ).
- [ ] Index khớp thứ tự: cột equality trước, cột range sau, cột `ORDER BY` cuối nếu cần tránh sort.
- [ ] Danh sách lớn có giới hạn số hàng. Phân trang sâu dùng keyset khi offset làm DB đọc bỏ hàng.
- [ ] `SELECT` lấy cột cần dùng trên đường trả nhiều hàng.
- [ ] Đổi schema có plan: khóa nào bị giữ, thời gian kỳ vọng theo kích thước bảng, có chặn đọc hay ghi.

Với Postgres đang có traffic, các mục sau là BLOCK:

- [ ] Tạo index bằng `CREATE INDEX CONCURRENTLY` trên bảng có ghi.
- [ ] Session migration đặt `lock_timeout` để không xếp hàng vô hạn phía sau một khóa.
- [ ] Thêm cột bắt buộc đi theo các bước tách nhau: thêm cột nullable và phát hành code ghi cột đó, backfill dữ liệu cũ theo lô có thể chạy lại, rồi chỉ siết `NOT NULL` / constraint (trên bảng lớn dùng `CHECK … NOT VALID` rồi `VALIDATE CONSTRAINT` trước) sau khi không còn phiên bản app cũ ghi null.
- [ ] Backfill lọc phần chưa điền, có điểm dừng, và không nằm chung một transaction với DDL khóa bảng.
- [ ] Bước phá dữ liệu (drop cột, siết kiểu) chạy sau khi phiên bản app cũ không còn đọc cột đó.

## G2 — Transaction

BLOCK

- [ ] Đổi schema hoặc mapping đi kèm test tạo hàng rồi đọc lại đúng cột, kể cả null và vi phạm unique.
- [ ] Một use case sở hữu commit. Tầng repository không tự commit ngoài ý use case.
- [ ] Transaction không chứa gọi HTTP, sleep, hay vòng lặp vô hạn trên tập lớn. Việc dài chạy theo lô, mỗi lô một transaction.
- [ ] Mức cô lập được nêu khi đường đó sợ lost update (tồn kho, số dư, ghế). Chọn optimistic (`version` → xung đột) hoặc `SELECT … FOR UPDATE`, rồi test hai phiên đồng thời.
- [ ] Deadlock hoặc serialization failure trên đường an toàn để thử lại có số lần tối đa. Đường không an toàn để thử lại thì trả lỗi, không lặp.
- [ ] Hiệu ứng ngoài DB (mail, push, event) không chạy khi transaction rollback. Ghi outbox trong cùng transaction với thay đổi nghiệp vụ, phát sau commit.

## G3 — Cờ đỏ

- Index không gắn với truy vấn nào, hoặc trùng index đã có.
- Denormalize mà không có cách làm tươi dữ liệu phái sinh.
- Sửa schema tay trên DB rồi quên đối chiếu entity.
- Migration không chạy lại được sau khi fail giữa chừng.
- Một request giữ connection từ đầu đến khi client bên ngoài trả lời.

## Mở thêm

- Hợp đồng API và nơi gọi transaction: [backend/GATES.md](../backend/GATES.md)
- Vì sao cần shard, replica, cache: [system-design/GATES.md](../system-design/GATES.md)
- Ngân sách kết nối: [network/GATES.md](../network/GATES.md)
