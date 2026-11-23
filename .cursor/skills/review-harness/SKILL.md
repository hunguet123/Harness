---
name: review-harness
description: >-
  Reviews a software change against the harness gates from an opposing pass.
  Use when the user asks for review, soát, kiểm tra xong chưa, or before
  marking a feature done. Do not use to implement the change.
---

# Soát harness

Nguồn: mục Review của [harness-engineering](https://github.com/github/awesome-copilot/blob/main/skills/harness-engineering/SKILL.md). Người soát chạy lại lệnh, không tin lời người viết.

## Việc phải làm

1. Đọc change brief và design note nếu có.
2. Đọc diff. Đối chiếu từng domain đã đánh dấu với `GATES.md`.
3. Chạy lại lệnh trong brief. Ghi pass hoặc fail.
4. Báo phát hiện theo mức: BLOCK còn thiếu bằng chứng, DECIDE còn bỏ trống, rồi ghi chú.

Tìm các lỗi sau trước:

- Cổng chung được chép vào task mà không có bằng chứng của project đích.
- Rule rủi ro cao không có test hoặc bước review.
- Lỗi đã gặp trong lúc làm nhưng không có failure memory và mục phát hiện.
- Retry, migration, hoặc ghi offline không có thử gửi lại.

Không sửa file trừ khi người dùng yêu cầu sửa.
