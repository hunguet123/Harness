---
name: harness-system-design
description: >-
  Runs a system-design reasoning loop and applies harness/system-design/GATES.md.
  Use when the user asks to design a system, estimate QPS or storage, choose
  cache, queue, shard, or consistency, or says system design, kiến trúc,
  ước lượng tải. Do not use for a single endpoint or a column change.
---

# System design

Phương pháp lấy từ [system-design](https://github.com/proyecto26/system-design-skills/blob/main/skills/system-design/SKILL.md): làm rõ, ước lượng, sơ đồ, đánh đổi, thử cách hỏng. Không chép catalog 21 building-block. Cổng cục bộ là [GATES.md](../../../system-design/GATES.md).

## Vòng

1. Phạm vi: việc có, việc không làm, latency, consistency theo loại dữ liệu.
2. Số có đơn vị: DAU, QPS trung bình, QPS đỉnh, dung lượng một năm, băng thông.
3. Sơ đồ ngữ cảnh và API người dùng thấy. Dừng để người dùng chốt trước khi đi sâu.
4. Mỗi lựa chọn một dòng: giải quyết gì, làm xấu gì, đổi khi tín hiệu nào.
5. Mỗi tầng mất một nút thì sao. Retry không phải câu trả lời cho dependency chết.
6. Viết phần đã chốt vào `harness/templates/design-note.md`.

## Khi vấn đề chuyển sang

| Việc | Skill kế |
| --- | --- |
| Endpoint, idempotency | `harness-backend` |
| Schema, index, transaction | `harness-database` |
| Timeout, retry, pool | `harness-network` |
| Màn hình web | `harness-frontend` |
| App trên máy, offline | `harness-mobile` |

Câu trả lời có bảng quyết định và một câu: phần nào vỡ trước khi tải tăng, và sẽ đổi gì.
