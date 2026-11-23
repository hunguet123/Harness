---
name: harness-network
description: >-
  Applies the harness network gate to outbound calls, timeouts, retries, TLS,
  pools, and health checks. Use when adding an HTTP or RPC client, webhook
  delivery, rate limit, or load balancer, or when the user says timeout, retry,
  mạng, idempotency. Do not use for schema design.
---

# Network

Cổng: [GATES.md](../../../network/GATES.md).

Thứ tự lấy từ [resilience](https://github.com/bricerising/enterprise-software-playbook/blob/main/skills/resilience/SKILL.md) và [sota resilience](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-architecture/rules/04-resilience-and-failure-design.md):

1. Timeout và hủy. Không để default của thư viện.
2. Idempotency nếu bước sau sẽ retry.
3. Retry có trần, backoff, jitter, đúng một lớp, nằm trong deadline.
4. Circuit breaker chỉ khi dependency fail-slow đã được đo. Một breaker cho một dependency.
5. Trần đồng thời từng dependency.

Phân loại lỗi: timeout, reset, 408, 429, 502, 503, 504 có thể retry nếu thao tác idempotent. 400, 401, 403, 404, 422 thì dừng. 429 có `Retry-After` thì chờ ít nhất khoảng đó.

Test: hết hạn trả lỗi đã đặt tên trong hạn; gửi lại không nhân đôi hiệu ứng.
