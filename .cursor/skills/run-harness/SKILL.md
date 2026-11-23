---
name: run-harness
description: >-
  Drives a software change through the independent harness gates G0–G3.
  Use when the user starts a feature, bugfix, or change and mentions harness,
  làm phần mềm, mobile, frontend, backend, system design, database, or network.
  Do not use for typos, formatting, or edits that do not change behavior.
---

# Chạy harness

Nguồn vòng: [harness-engineering](https://github.com/github/awesome-copilot/blob/main/skills/harness-engineering/SKILL.md). Cổng đầy đủ nằm ở file domain, không chép lại vào đây.

## Việc phải làm

1. Điền brief từ `harness/templates/change-brief.md`. Stack và lệnh test là của project đích.
2. Đánh dấu domain. Một task thường 2–3 domain. System design trước nếu còn đang chọn thành phần.
3. Đụng API, schema, hợp đồng UI, timeout/retry, hoặc offline thì viết `harness/templates/design-note.md` trước code.
4. Đọc skill domain tương ứng, rồi đọc `GATES.md` của domain đó. Áp mục BLOCK.
5. Chạy lệnh đã ghi trong brief. Dán kết quả.
6. Lượt hai đối chiếu diff với cổng. Lỗi có thể lặp thì dùng `harness/templates/failure-memory.md`.

## Định tuyến

| Domain trong brief | Skill |
| --- | --- |
| System design | `harness-system-design` |
| Backend | `harness-backend` |
| Database | `harness-database` |
| Network | `harness-network` |
| Frontend | `harness-frontend` |
| Mobile | `harness-mobile` |
| Cần browser hoặc database thật | `harness-mcp` |

Thiếu bằng chứng ở mục BLOCK thì chưa báo xong.
