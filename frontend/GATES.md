# Frontend

Mở khi thêm hoặc đổi màn hình web, form, trạng thái máy chủ, hoặc hợp đồng vùng UI. Bộ này trung lập framework. Luật mạng (timeout, retry) nằm ở Network. Nếu cùng thay đổi có API mới, mở Backend trước và khóa hợp đồng response.

Nguồn tinh chỉnh: pattern frontend của [harness-claude-code](https://github.com/MartinKChen/harness-claude-code) (trạng thái, vùng accessible, invalidate sau mutation) và câu hỏi nền tảng của [frontend-system-design](https://github.com/devkodeio/frontend-system-design).

## Bản đồ module và ngôn ngữ

Chiều phụ thuộc một chiều cho ứng dụng Web (khóa bằng linter ranh giới module khi repo hỗ trợ):

```text
app-shell ──► features/<ten-mien> ──► data-access ──► shared (ui, lib, config)
```

- `app-shell`: khởi tạo ứng dụng, bảng định tuyến (`router`), khung bố cục chung, cổng kiểm phiên/quyền, `ErrorBoundary` toàn cục và các provider nền.
- `features/<ten-mien>`: màn hình, luồng biểu mẫu, kiểm tra input biên phía client, và state giao diện cục bộ của miền nghiệp vụ đó. **Cấm hai `features/*` import thẳng ruột nội bộ của nhau** (giao tiếp qua điều hướng URL, callback ở `app-shell`, hoặc hạ phần dùng chung xuống `data-access`/`shared`).
- `data-access` (`entities` / `api`): HTTP client tập trung, định nghĩa khóa cache/invalidation cho dữ liệu máy chủ, ánh xạ DTO API sang mô hình hiển thị, truyền `AbortSignal` hủy request cũ.
- `shared/ui`: các thành phần giao diện gốc (nút, ô nhập, hộp thoại, bảng, thông báo) đã gắn chuẩn vai trò ngữ nghĩa (`role`), nhãn accessible và điều hướng bàn phím; không chứa logic gọi mạng hay nghiệp vụ.
- `shared/lib` & `config`: tiện ích thuần (định dạng ngày/tiền/chuỗi) và bộ đọc biến môi trường public đã kiểm kiểu.

**Hồ sơ ngôn ngữ Frontend:** chuẩn mặc định là **TypeScript** (cùng HTML ngữ nghĩa & CSS) — đọc kèm [languages/typescript.md](../languages/typescript.md) và hợp đồng API tại [languages/sql-idl.md](../languages/sql-idl.md).

## G1 — Bề mặt

DECIDE, ghi trong design note hoặc brief:

- [ ] Nền tảng: desktop, mobile web, hay cả hai.
- [ ] Responsive một layout, hay adaptive theo breakpoint. Hướng làm: mobile-first khi bề mặt chính là điện thoại.
- [ ] Dữ liệu màn hình đến từ đâu: một module gọi API. Component lá không tự tạo client HTTP rải rác.

BLOCK

- [ ] Mỗi màn hình liệt kê trạng thái: loading, có dữ liệu, rỗng, lỗi, và gửi lại. Trạng thái lỗi có hành động thử lại khi lỗi là tạm thời.
- [ ] Vùng người dùng tương tác có vai trò và tên accessible ổn định (nút, ô nhập, thông báo). Tên đó là hợp đồng để test và để người dùng công cụ trợ năng tìm thấy.
- [ ] Form kiểm tra ở biên trước khi gọi API. Lỗi server map về đúng field hoặc về một thông báo chung, không mất dữ liệu người dùng vừa gõ.
- [ ] Mutation thành công làm tươi đúng vùng đang hiển thị (danh sách và chi tiết nếu cả hai đang giữ bản sao).
- [ ] Mutation thất bại hoàn tác cập nhật lạc quan và nói cho người dùng. Hoàn tác im lặng là mất dữ liệu trên UI.
- [ ] Không nhúng token, khóa, hay bí mật vào bundle. Phiên dùng cơ chế HttpOnly hoặc kho mà chính sách dự án đã chọn, ghi rõ chỗ lưu.
- [ ] Danh sách dài có cách dừng (phân trang hoặc cửa sổ ảo). Một lần tải cả bảng lớn là quyết định có chủ đích với ước lượng kích thước.

## G2 — Kiểm tra

BLOCK

- [ ] Test render các trạng thái đã liệt kê, tìm vùng theo vai trò và tên, không theo class CSS.
- [ ] Đường lỗi: API 4xx/5xx hoặc mạng đứt cho thấy trạng thái lỗi và không xóa form.
- [ ] Đường gửi lại sau thành công không tạo hai yêu cầu khác khóa nếu người dùng bấm đúp. Khóa bấm hoặc idempotency key nằm ở một chỗ.
- [ ] Điều hướng tới màn hình mới đi từ một lối vào thật (shell, menu, hoặc màn cha), không chỉ mount thử component.

Ghi lệnh test, typecheck, và lint của project đích vào brief. Ảnh một mình không thay test trạng thái.

## G3 — Cờ đỏ

- Spinner không có lối thoát khi request không bao giờ về. Phải có timeout nhìn thấy được, nối với [network/GATES.md](../network/GATES.md).
- Cache UI giữ dữ liệu của user A sau khi user B đăng nhập trên cùng trình duyệt.
- Màu là cách duy nhất để báo lỗi.
- Gọi API khi mở màn hoặc đổi bộ lọc mà không hủy hay bỏ qua kết quả cũ khi rời màn, khiến response về muộn ghi đè dữ liệu mới.
- Sửa hợp đồng field API trong component mà Backend chưa đổi, hoặc ngược lại.

## Mở thêm

- App cài trên máy, offline, push: [mobile/GATES.md](../mobile/GATES.md)
- Shape API: [backend/GATES.md](../backend/GATES.md)
- Deadline của request: [network/GATES.md](../network/GATES.md)
