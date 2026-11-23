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

1. Đọc change brief và design note của task. Thay đổi hành vi mà thiếu change brief là BLOCK ở G0; đụng ranh giới G1 (API, schema, hợp đồng UI, timeout/retry, offline) mà thiếu design note là BLOCK ở G1.
2. Đọc diff (hoặc design note nếu phạm vi chỉ là thiết kế). Đối chiếu từng domain đã đánh dấu với `GATES.md`.
3. Chạy lại lệnh trong brief (trừ các mục ghi `K/A` có lý do hợp lệ). Ghi pass hoặc fail.
4. Báo phát hiện theo mức: BLOCK còn thiếu bằng chứng, DECIDE còn bỏ trống, rồi ghi chú.

Tìm các lỗi sau trước:

- Cổng chung được chép vào task mà không có bằng chứng của project đích.
- Đánh dấu "trên nền có sẵn" trong brief để né **Chuẩn nền service** trong khi diff thực tế có tạo service/client/pool mới hoặc sửa bootstrap.
- Rule rủi ro cao không có test hoặc bước review.
- Lỗi đã gặp trong lúc làm nhưng không có failure memory và mục phát hiện.
- Retry, migration, hoặc ghi offline không có thử gửi lại.
- Ghi đè trực tiếp file trong `templates/`, hoặc để sót server tạm trong `.cursor/mcp.json` sau khi xong task.

Không sửa file trừ khi người dùng yêu cầu sửa.
