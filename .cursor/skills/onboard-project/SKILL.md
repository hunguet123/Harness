---
name: onboard-project
description: >-
  Discovers a new or existing repository's stack, verified commands, module layout,
  and footguns, then populates harness/PROJECT.md (and AGENTS.md if present).
  Use once after installing the harness or when the user says onboard, khảo sát
  dự án, khởi tạo harness cho repo, or map cấu trúc dự án.
---

# Khảo sát và gắn Harness vào dự án (`onboard-project`)

Nguồn phương pháp: pha Discovery & Bootstrap của [harness-engineering](https://github.com/github/awesome-copilot/blob/main/skills/harness-engineering/SKILL.md) và [ai-repo-harness-guide](https://github.com/adobe/ai-repo-harness-guide/blob/main/guide/07-Build-Your-Harness.md).

Mục tiêu: biến bộ cổng chung thành **hợp đồng gắn chặt với thực tế repo này** chỉ trong một lần quét, để các phiên sau không phải dò lại từ đầu.

## Việc phải làm

1. **Đọc cấu hình thực tế của repo (không đoán):**
   - Đọc manifest (`package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `*.csproj`, `Package.swift`, `pubspec.yaml`), `Makefile`, và workflow CI (`.github/workflows/*`, `.gitlab-ci.yml`) nếu có.
   - Đọc `README.md` và các tài liệu kiến trúc sẵn có trong `docs/`, nhưng coi tên lệnh/đường dẫn trong tài liệu cũ là giả thuyết cho tới khi đối chiếu khớp với file thật.
2. **Xác minh bộ lệnh kiểm chứng G2:**
   - Nếu là **dự án đã có**: chạy thử các lệnh không phá dữ liệu (typecheck, lint, hoặc test nhanh) để chắc chắn lệnh chạy được; lệnh nào thiếu hoặc cần dịch vụ ngoài (Docker/DB) thì ghi rõ điều kiện chạy.
   - Nếu là **dự án mới chưa có code**: đối chiếu với người dùng theo ma trận [languages/README.md](../../../languages/README.md), chốt stack + cây thư mục module chuẩn trước khi khởi tạo.
3. **Ánh xạ cây thư mục vào Bản đồ Module:**
   - Mở `GATES.md` của các mảng dự án có dùng (`backend`, `frontend`, `mobile`, `database`, `network`) và ghi rõ thư mục nào của repo đóng vai trò `domain`, `application`, `transport`, `persistence`, `features/*`, `data-access`, `local-store`, `sync-outbox`.
   - Ghi nhận ngay các điểm lệch hiện hữu (ví dụ controller cũ đang gọi thẳng ORM) vào mục **Known Footguns** để code mới không chép theo mẫu xấu đó.
4. **Cập nhật hồ sơ dự án:**
   - Ghi kết quả vào `harness/PROJECT.md` (tạo từ [project-profile.md](../../../templates/project-profile.md) nếu chưa có).
   - Nếu gốc dự án có khối `<!-- >>> harness-agents >>> -->` trong `AGENTS.md`, kiểm tra các đường dẫn dẫn chiếu khớp với dự án.

Không tự ý đổi tên thư mục hay refactor code sản phẩm trong bước khảo sát này trừ khi người dùng yêu cầu.
