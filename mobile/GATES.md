# Mobile

Mở khi làm app iOS, Android, React Native, Flutter, hoặc Kotlin Multiplatform. Web responsive nằm ở Frontend. File này giữ bất biến trên máy người dùng: mạng điện thoại mất giữa chừng, process bị giết, và nhiều thiết bị cùng một tài khoản.

Nguồn tinh chỉnh: lớp local-truth / outbox / BFF từ [awesome-architecture mobile-app](https://github.com/study8677/awesome-architecture/blob/main/en/templates/mobile-app/README.md), luật offline từ [sota-mobile](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-mobile/rules/03-offline-background-push.md), checklist lưu trữ và trạng thái từ [oh-my-agent](https://github.com/first-fluke/oh-my-agent/blob/main/skills/oma-mobile/resources/checklist.md).

## G1 — Tư thế mạng

DECIDE trước khi viết màn hình. Một app có thể chọn khác nhau theo từng tính năng.

| Tư thế | Khi nào | Hệ quả bắt buộc |
| --- | --- | --- |
| Online, có UX khi mất mạng | Dữ liệu cũ nguy hiểm (giá realtime, điều phối) | Banner mất mạng, hành động bị khóa, không spinner vô hạn |
| Offline-first | Nội dung, tin nhắn, việc hiện trường | UI đọc bản cục bộ. Mạng chỉ ghi vào bản cục bộ |

BLOCK

- [ ] Tư thế của từng màn hoặc từng entity được ghi trong design note.
- [ ] Token và khóa nằm trong kho mã hóa của hệ điều hành (Keychain, Keystore, hoặc wrapper tương đương). Không nằm trong prefs thường, AsyncStorage, hay MMKV thường.
- [ ] Entity ghi được khi offline có chiến lược xung đột, một dòng mỗi entity: last-write-wins có mốc thời gian server, merge từng field, hoặc so phiên bản (`base_version` → 409). Dữ liệu nhiều người sửa mà dùng last-write-wins im lặng là BLOCK.
- [ ] API mobile có phiên bản. Trường mới thì client cũ bỏ qua được. Trường bị xóa chỉ xóa sau khi phiên bản app cũ không còn trong hỗ trợ.
- [ ] Payload danh sách bị cắt cho đường di động: một round-trip cho một màn khi có thể. Nhiều gọi lẻ được ghi lý do (quyền, cache khác nhau).

## G1 — Offline-first

Áp dụng khi tư thế là offline-first.

BLOCK

- [ ] UI không render thẳng body HTTP. Đọc từ DB hoặc store cục bộ đã được network cập nhật.
- [ ] Ghi cục bộ và hàng outbox nằm trong cùng một commit. Giết app giữa chừng không mất thao tác đã hiện trên UI, và không tạo hàng outbox mà không có thay đổi cục bộ.
- [ ] Mỗi mutation có idempotency key sinh từ client. Server dedupe. Thiếu key trên đường retry là BLOCK.
- [ ] Outbox giữ thứ tự trên cùng một aggregate. Aggregate khác được gửi song song có trần.
- [ ] Hết hạn thử lại hoặc gặp 4xx từ chối nghiệp vụ (trừ `401` làm mới phiên một lần và `409` chạy chiến lược xung đột) thì dừng, hiện cho người dùng, và ghi telemetry. Không retry vô hạn một mutation bị từ chối.
- [ ] Trạng thái pending hiện sau vài giây. Thất bại cuối thì hoàn tác bản cục bộ và có lối gửi lại.
- [ ] Ảnh và video là đối tượng riêng, upload theo tham chiếu. Không nhét blob vào hàng sync.

## G2 — Vòng đời app

BLOCK

- [ ] Màn có trạng thái loading, rỗng, lỗi, offline. Lỗi có thử lại.
- [ ] Request có timeout. Mất mạng chuyển trạng thái offline đã thiết kế, không kẹt loading.
- [ ] Công việc nền dùng scheduler của nền tảng, có backoff. Không giữ vòng lặp tự viết khi app bị suspend.
- [ ] Push chỉ đánh thức app để kéo thay đổi hoặc hiện thông báo. Nội dung nhạy cảm không nằm trọn trong payload push nếu máy khóa có thể hiện thông báo.
- [ ] Đăng xuất xóa token trong kho bảo mật và xóa hàng cục bộ của tài khoản đó.

## G2 — Kiểm tra

BLOCK

- [ ] Một test hoặc kịch bản tay: máy bay bật, tạo một ghi, mở lại app, ghi vẫn còn và được gửi khi có mạng, server chỉ nhận một lần.
- [ ] Hai lần gửi cùng idempotency key không tạo hai bản ghi. **Bằng chứng:** test server (Backend) cộng với ghi chú client gửi lại cùng key.
- [ ] `401` làm mới phiên tối đa một lần ở lớp auth rồi gửi lại cùng idempotency key, hoặc đưa về đăng nhập. Vòng lặp refresh là BLOCK.

## G3 — Cờ đỏ

- Cache danh sách và màn chi tiết lệch nhau sau một lần sửa.
- Last-write-wins trên bản ghi nhiều người sửa mà không ghi trong design note.
- Đồng bộ tự viết bằng tay cho tài liệu cộng tác. Dùng engine hoặc CRDT có sẵn, hoặc hạ phạm vi xuống một người ghi.
- Log request có header `Authorization`.

## Mở thêm

- Hợp đồng API và idempotency phía server: [backend/GATES.md](../backend/GATES.md)
- Timeout, retry, TLS: [network/GATES.md](../network/GATES.md)
- Schema phiên bản và conflict trên server: [database/GATES.md](../database/GATES.md)
- Cùng nguyên tắc trạng thái UI nếu chia sẻ web: [frontend/GATES.md](../frontend/GATES.md)
