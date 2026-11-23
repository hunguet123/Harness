# TypeScript / JavaScript

Áp dụng cho **Backend** (Node.js, Bun — NestJS, Fastify, Hono, Express), **Frontend Web** (React, Next.js, Vue, Nuxt, Angular, SvelteKit), và **Mobile** (React Native, Expo). Đọc kèm cổng domain tương ứng: [backend](../backend/GATES.md), [frontend](../frontend/GATES.md), [mobile](../mobile/GATES.md), [network](../network/GATES.md).

## Tổ chức module và khóa ranh giới

- Bật `strict: true`, `noImplicitOverride: true`, và ưu tiên `noUncheckedIndexedAccess: true` trong `tsconfig.json`.
- Khóa chiều import giữa các module bằng công cụ tĩnh (`eslint-plugin-boundaries`, `dependency-cruiser`, hoặc `@nx/enforce-module-boundaries`), không dựa vào nhắc miệng:
  - **Backend:** `transport` → `application` → `domain`; `persistence` / `integrations` / `jobs` chỉ phụ thuộc hướng vào `application` và `domain`.
  - **Frontend / React Native:** `app` → `features/*` → `data-access` → `shared`; cấm hai `features/*` import thẳng file nội bộ của nhau.
- Không xuất tràn qua `index.ts` (barrel file) gây vòng phụ thuộc ẩn hoặc kéo code server vào bundle client.

## Ràng buộc bắt buộc (BLOCK)

- **Kiểm tra dữ liệu lúc chạy ở biên:** kiểu TypeScript biến mất khi chạy. Mọi body/query/param HTTP, payload webhook, message queue, và biến môi trường phải qua bộ parse runtime (`zod`, `valibot`, `typebox`, hoặc `class-validator` bật `whitelist: true` + `forbidNonWhitelisted: true`).
- **Quản lý Promise và hủy tác vụ:** bật ESLint `@typescript-eslint/no-floating-promises` và `no-misused-promises`. Cuộc gọi mạng/DB dài nhận `AbortSignal` để hủy khi hết hạn hoặc khi người dùng rời màn hình.
- **Tách bí mật khỏi client bundle:** biến môi trường có tiền tố public (`NEXT_PUBLIC_`, `VITE_`, `EXPO_PUBLIC_`, `PUBLIC_`) tuyệt đối không chứa secret, khóa ký, hay connection string.
- **Không nghẽn event loop:** trên Backend Node/Bun và JS thread của React Native, không chạy vòng lặp CPU nặng, regex dễ backtracking, hay hàm `*Sync` (`fs.readFileSync`, `crypto.pbkdf2Sync`) trên đường phục vụ request/UI.

## Lệnh kiểm chứng chuẩn cho G2

Ghi lệnh thực tế theo package manager của dự án (`pnpm`, `npm`, `yarn`, `bun`) vào `change-brief.md`:

- Kiểm kiểu: `tsc --noEmit` (hoặc `vue-tsc --noEmit` / `astro check`)
- Lint & ranh giới module: `eslint .` / `depcruise src`
- Test: `vitest run` / `jest` / `playwright test`
- Build: lệnh build sản phẩm của repo

## Cờ đỏ khi soát G3

- Ép kiểu `as SomeType` hoặc dùng `any` trên dữ liệu vừa đọc từ `req.body`, `fetch()`, hoặc hàng đợi mà chưa qua schema runtime.
- `async` handler trong Express 4 hoặc event listener không bắt lỗi khiến unhandled rejection làm sập process.
- Dùng số thực `number` của JS để cộng trừ tiền tệ thay vì số nguyên đơn vị nhỏ nhất (`bigint`/integer cents) hoặc thư viện thập phân.
- Trên Next.js / SSR: import module chứa DB hoặc biến bí mật vào file có `'use client'`, hoặc giữ state theo request trong biến toàn cục của module server.
