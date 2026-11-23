---
name: harness-backend
description: >-
  Applies the harness backend gate to APIs, use cases, authorization, jobs,
  and idempotent writes. Use when designing or changing an API, auth, webhook,
  or background job, or when the user says backend, API, phân quyền.
  Do not use for schema-only work (harness-database) or client screens.
---

# Backend

Cổng: [GATES.md](../../../backend/GATES.md).

Hình từ [harness-kit backend](https://github.com/romabeckman/harness-kit/blob/main/agents/developer-backend.md) và nguyên tắc stack-trung lập của [fullstack-agent-skills](https://github.com/suleyman/fullstack-agent-skills): API sở hữu dữ liệu, client cũ không bị gãy bởi field bắt buộc mới, một commit cho một use case. Không khóa FastAPI, Nest, hay một ORM.

## Trước khi viết handler

- Hợp đồng: method, path, status, mã lỗi, một ví dụ body.
- Validation ở biên. Phán quyền và chủ sở hữu trước khi đổi trạng thái.
- Ghi có thể gửi lại: khóa idempotency hoặc unique. Cùng key, body khác → xung đột.
- Transaction không chứa gọi HTTP. Sự kiện ra ngoài đi sau commit hoặc qua outbox.

## Bằng chứng

- Unit cho logic. Integration khi đổi biên hoặc kho.
- Test ghi rồi đọc lại từ kho.
- Ghi lệnh của project đích vào change brief. Không bịa lệnh `npm test` nếu project không dùng npm.
