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

Đường dẫn dưới đây tính từ gốc bộ harness (thêm tiền tố `harness/` nếu đặt làm thư mục con):

1. Copy [change-brief.md](../../../templates/change-brief.md) sang bản ghi của task ở project đích rồi điền (không sửa trực tiếp file trong `templates/`). Stack và lệnh test là của project đích.
2. Đánh dấu domain. Một task thường 2–3 domain. System design trước nếu còn đang chọn thành phần.
3. Đụng API, schema, hợp đồng UI, timeout/retry, hoặc offline thì copy [design-note.md](../../../templates/design-note.md) sang cạnh brief và viết trước code.
4. Đọc skill domain tương ứng, rồi đọc `GATES.md` của domain đó. Áp mục BLOCK.
5. Chạy lệnh đã ghi trong brief (hoặc ghi `K/A — lý do` khi phạm vi chỉ là thiết kế). Dán kết quả.
6. Lượt hai đối chiếu diff với cổng. Lỗi có thể lặp thì copy [failure-memory.md](../../../templates/failure-memory.md) sang nơi lưu lỗi của project đích.

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
