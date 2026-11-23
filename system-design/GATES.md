# System Design

Mở file này trước các domain khác khi thêm dịch vụ, đổi luồng dữ liệu, chọn mô hình consistency, hoặc ước lượng tải. Đây là cổng quyết định. Chi tiết bảng, API, và timeout nằm ở Database, Backend, Network.

Nguồn tinh chỉnh: checklist phạm vi, ước lượng, và tín hiệu chọn thành phần từ [systems-design.skill](https://github.com/ryanthedev/systems-design.skill/blob/main/skills/distributed-systems-design/references/checklists.md), bản đồ ngữ cảnh từ [backend-things](https://github.com/rendyspratama/backend-things).

## G1 — Phạm vi và số

BLOCK

- [ ] Trong phạm vi và ngoài phạm vi được viết thành danh sách. **Bằng chứng:** design note.
- [ ] Nền tảng người dùng: web, mobile, hay cả hai. Nội dung: chữ, ảnh, video, file.
- [ ] Latency mục tiêu của đường chính (ví dụ đọc < 300 ms, ghi chấp nhận async).
- [ ] Consistency được chọn theo từng loại dữ liệu: mạnh, eventual, hoặc theo phiên bản. Im lặng trên dữ liệu tiền, tồn kho, hoặc quyền là BLOCK.
- [ ] Mất dữ liệu có được chấp nhận không. Nếu không: số bản sao và cách phục hồi được nêu tên.
- [ ] Ước lượng có đơn vị: DAU, hành động mỗi user mỗi ngày, QPS trung bình, QPS đỉnh, dung lượng một năm, băng thông vào/ra. Số làm tròn được phép khi giả định nằm cạnh số.

Công thức tối thiểu, ghi trong design note:

| Đại lượng | Cách tính |
| --- | --- |
| QPS trung bình | DAU × hành động / 86 400 |
| QPS đỉnh | QPS trung bình × hệ số đỉnh (ghi hệ số) |
| Dung lượng/ngày | DAU × hành động × kích thước đối tượng |
| Băng thông | QPS × kích thước đối tượng |

DECIDE

- [ ] SLA kỳ vọng (99%, 99.9%, 99.99%) và phút chết cho phép trong năm.
- [ ] Một vùng hay nhiều vùng. Nhiều vùng thì xung đột ghi được xử lý ở đâu.

## G1 — Thành phần chỉ thêm khi có tín hiệu

Mỗi thành phần mới cần một dòng "tín hiệu → chọn → cách hỏng". Thêm cho đủ sơ đồ là BLOCK ngược: phải xóa khỏi phạm vi.

| Tín hiệu | Cân nhắc | Chưa thêm khi |
| --- | --- | --- |
| Read:write > 5:1 và cùng một tập bị đọc lặp | Cache, TTL, nhiều nút | Dữ liệu đổi mỗi request, hoặc cần đọc mạnh ngay sau ghi |
| Ảnh, JS, video cho user phân tán | CDN, fallback về origin | Toàn bộ nội dung động, một vùng, ít truy cập |
| Xử lý không cần trả lời trong request | Hàng đợi riêng theo việc, DLQ, đo độ sâu hàng | Mọi thao tác cần kết quả đồng bộ |
| Một máy DB không chứa nổi dung lượng hoặc write QPS | Replica đọc trước, shard sau khi đã có khóa phân mảnh | Join xuyên bản ghi là đường chính và dữ liệu vẫn vừa một máy |
| API public hoặc chi phí bên thứ ba | Rate limit phía server, HTTP 429, `Retry-After` | Giới hạn chỉ nằm ở client |
| Server đẩy sự kiện realtime hai chiều | WebSocket hoặc kênh push của nền tảng | Thông báo thưa, một chiều: polling có ngân sách là đủ |
| Hơn một process phục vụ request | Load balancer và health check | Một process local cho bài lab |

BLOCK

- [ ] Sơ đồ ngữ cảnh: hệ thống này, actor, dependency ngoài, chiều dữ liệu.
- [ ] Web/API stateless, hoặc session nằm ở kho dùng chung. Session dính một máy được ghi là quyết định có chủ đích kèm cách hết hạn.
- [ ] Mỗi tầng có cách mất một nút. Một máy duy nhất cho dữ liệu sản xuất là quyết định tạm, có tín hiệu sẽ thêm replica.
- [ ] Đường nóng có metric: QPS, latency, tỉ lệ lỗi, độ sâu hàng đợi nếu có queue.
- [ ] Bí mật và luật nhạy cảm nằm phía server. Client không giữ khóa ký.

## G3 — Cờ đỏ

Soát design note. Gặp mục sau thì sửa note trước khi code:

- Nhảy vào bảng và endpoint khi chưa có QPS, dung lượng, và consistency.
- Thêm shard, cache, và queue trong cùng một thay đổi nhỏ mà ước lượng vẫn vừa một process.
- Tuyên bố consistency mạnh trong khi cache ghi rồi đọc không có quy tắc hết hạn.
- `hash(key) % N` cho tập nút thay đổi.
- Khóa shard là id của thực thể nổi tiếng (một user, một sản phẩm) mà không có đường tách nóng.
- Coi hàng đợi là exactly-once. Ghi idempotent nằm ở Backend và Database.

## Mở thêm

- API và phân quyền: [backend/GATES.md](../backend/GATES.md)
- Schema và transaction: [database/GATES.md](../database/GATES.md)
- Timeout và retry: [network/GATES.md](../network/GATES.md)
- Client: [frontend/GATES.md](../frontend/GATES.md), [mobile/GATES.md](../mobile/GATES.md)
