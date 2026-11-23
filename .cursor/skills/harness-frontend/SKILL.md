---
name: harness-frontend
description: >-
  Applies the harness frontend gate to web screens, forms, and UI states.
  Use when building or changing a web page, form, loading or error state,
  or when the user says frontend, UI, màn hình web, accessibility.
  Do not use for native mobile apps (harness-mobile) or API implementation.
---

# Frontend

Cổng: [GATES.md](../../../frontend/GATES.md).

Giữ phần kiểm được từ [fullstack-agent-skills](https://github.com/suleyman/fullstack-agent-skills): trạng thái loading, rỗng, lỗi, thử lại là một phần của tính năng; state máy chủ và state UI tách nhau. Bỏ khóa Next.js, Tailwind, và một thư viện data-fetching. Project đích chọn thư viện và ghi vào brief.

## Trước khi vẽ component

- Nền tảng và một lối vào thật tới màn hình.
- Hợp đồng vùng: vai trò và tên accessible.
- Mutation làm tươi đúng bản sao, hoặc hoàn tác và báo lỗi.
- Không đưa bí mật vào bundle.

## Bằng chứng

- Test tìm vùng theo vai trò và tên, gồm trạng thái lỗi không xóa form.
- Cần trang đang chạy, log mạng, hoặc trace: đọc `harness-mcp` và chỉ bật `chrome-devtools` khi brief yêu cầu. Ảnh không thay các trạng thái trên.
