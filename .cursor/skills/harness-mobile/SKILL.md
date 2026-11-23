---
name: harness-mobile
description: >-
  Applies the harness mobile gate to native and cross-platform apps, offline
  sync, push, and on-device secrets. Use when the user mentions iOS, Android,
  React Native, Flutter, offline, outbox, or push. Do not use for responsive
  websites (harness-frontend).
---

# Mobile

Cổng: [GATES.md](../../../mobile/GATES.md).

Từ [mobile-architecture](https://github.com/amritmalla/claude-full-stack-2.0/blob/HEAD/skills/architecture/mobile-architecture/SKILL.md): app là hệ phân tán bị ràng buộc — mạng đứt, pin, process bị giết. Chọn native, React Native, Flutter, hay KMP là một quyết định trong design note, không phải mặc định.

Từ [sota-mobile](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-mobile/rules/03-offline-background-push.md):

- Khai báo online-có-UX-mất-mạng hoặc offline-first cho từng tính năng.
- Offline-first: UI đọc bản cục bộ. Ghi cục bộ và outbox cùng một commit. Idempotency key trên mọi mutation.
- Xung đột ghi theo entity. Nhiều người sửa thì không last-write-wins im lặng.
- Token ở Keychain hoặc Keystore.

API thêm field thì client cũ bỏ qua được. Kiểm tra: mất mạng, giết app, mở lại, server chỉ nhận một lần.
