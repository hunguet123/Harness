---
name: harness-database
description: >-
  Applies the harness database gate to schemas, indexes, migrations, queries,
  and transactions. Use when the user mentions database, SQL, schema, migration,
  index, EXPLAIN, transaction, or khóa. Do not use for API shape alone
  (harness-backend) or for picking a cache before there is a measured query.
---

# Database

Cổng: [GATES.md](../../../database/GATES.md).

Cách làm lấy từ [sota-databases](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-databases/SKILL.md): chọn chế độ trước, không tải mọi rule. Postgres là engine mẫu cho DDL online. Engine khác vẫn giữ invariant, index theo truy vấn, và transaction ngắn.

## Chọn chế độ

**Làm mới** — schema, migration, truy vấn:

1. Luật không được sai thì thành constraint, không chỉ thành if trong code.
2. Mỗi thay đổi schema là migration. Bảng có traffic: expand, backfill theo lô, rồi mới siết.
3. Viết truy vấn nóng kèm index sẽ dùng.
4. Ghi cách đồng thời: isolation, khóa hoặc version, retry có trần.

**Soát** — database có sẵn:

1. Đối chiếu constraint với luật nghiệp vụ.
2. Xin `EXPLAIN` cho đường nóng. Thiếu plan thì nói thiếu, không bịa.
3. Tìm transaction dài và N+1.

Đọc lại hàng sau ghi. Unique và null có test.
