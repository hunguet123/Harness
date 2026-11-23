# Swift (iOS) và Dart (Flutter)

Áp dụng cho **Mobile iOS gốc** (SwiftUI, UIKit) và **Mobile đa nền tảng Flutter**. Với Android Kotlin / KMP xem [jvm.md](jvm.md); với React Native / Expo xem [typescript.md](typescript.md). Đọc kèm cổng: [mobile](../mobile/GATES.md), [network](../network/GATES.md).

## 1. Swift (iOS — SwiftUI / UIKit)

### Tổ chức module
- Tách bằng **Swift Package Manager (Local Packages)** theo chiều một chiều: `AppTarget` → `Features/*` (màn hình + `@Observable` ViewModel, các feature không import nhau) → `SyncOutbox` & `LocalStore` (SwiftData / CoreData / GRDB) & `NetworkClient` (`URLSession` cấu hình riêng) & `DeviceSecurity` (Keychain, Push, `BGTaskScheduler`) → `CoreDomain`.

### Ràng buộc bắt buộc (BLOCK)
- **Swift Concurrency và hủy tác vụ:** cập nhật giao diện trên `@MainActor`. Tác vụ gắn với vòng đời màn hình đặt trong `.task { ... }` của SwiftUI hoặc giữ `Task` handle để `.cancel()` khi rời màn; kiểm `try Task.checkCancellation()` trước khi ghi đè state sau bước chờ mạng.
- **Không rò bộ nhớ và không chặn luồng chính:** closure sống lâu hoặc callback hệ thống phải bắt `[weak self]`. Thao tác cơ sở dữ liệu hàng loạt, giải mã ảnh/JSON lớn chạy trên background actor/context, không chạy trên main thread.
- **Lưu trữ bảo mật và mạng:** token phiên cất trong **Keychain** (với mức truy cập phù hợp như `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), cấm để trong `UserDefaults`. Tạo `URLSessionConfiguration` có `timeoutIntervalForRequest` và `timeoutIntervalForResource` tường minh.

### Lệnh kiểm chứng G2 (Swift)
- Kiểm tra & test package: `swift test` hoặc `xcodebuild test -scheme <Scheme> -destination 'platform=iOS Simulator,...'`
- Lint: `swiftlint lint --strict` (nếu dự án dùng SwiftLint)

---

## 2. Dart (Flutter)

### Tổ chức module
- Bố cục thư mục `lib/` hoặc multi-package workspace: `app/` (router, DI, lifecycle observer) → `features/<ten>/` (`presentation/`, `application/` — không import chéo giữa các `features/*`) → `data/` (`local_db` với Drift/Sqflite, `outbox_sync`, `remote_api`, `secure_storage`) → `core/` (kiểu miền, lỗi chuẩn, widget nền có `Semantics`).

### Ràng buộc bắt buộc (BLOCK)
- **Phân tích tĩnh nghiêm ngặt:** cấu hình `analysis_options.yaml` bật `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`. Không để lọt `dynamic` ở DTO và state màn hình.
- **An toàn vòng đời Widget và bất đồng bộ:** sau mọi lệnh `await` trong Widget/State, bắt buộc kiểm `if (!context.mounted) return;` trước khi điều hướng, mở dialog, hay đọc `InheritedWidget`. Không phóng `Future` mồ côi không bắt lỗi.
- **Giữ mượt khung hình và bảo mật thiết bị:** giải mã dữ liệu lớn hoặc xử lý nặng chuyển sang `Isolate.run(...)`. Token lưu qua `flutter_secure_storage` (Keychain/Keystore), cấm lưu trong `shared_preferences` hoặc bảng SQLite không mã hóa.
- **Accessibility:** nút bấm bằng icon hoặc widget tùy biến phải có `Semantics` / `tooltip` để trình đọc màn hình và widget test tìm theo nhãn ngữ nghĩa (`find.bySemanticsLabel` / role).

### Lệnh kiểm chứng G2 (Dart / Flutter)
- Kiểm tĩnh: `dart analyze --fatal-infos` (hoặc `flutter analyze`)
- Định dạng: `dart format --output=none --set-exit-if-changed .`
- Test: `flutter test` (unit + widget test cho đủ các trạng thái `loading`, `empty`, `error`, `offline`)

## Cờ đỏ chung khi soát G3 (Swift & Dart)

- Màn hình ở chế độ offline-first nhưng gọi thẳng API và gán vào state UI mà không đi qua kho cục bộ + hàng `outbox`.
- Bấm nút gửi form nhiều lần khi mạng chập chờn sinh ra các request khác `idempotency_key` hoặc gửi trùng không khóa nút.
- Payload push notification mang sẵn dữ liệu nhạy cảm hiển thị trên màn hình khóa thay vì chỉ báo có thay đổi để app tự đồng bộ.
