# Java và Kotlin (JVM, Android, KMP)

Áp dụng cho **Backend JVM** (Spring Boot, Ktor, Quarkus, Micronaut) và **Mobile Android / Kotlin Multiplatform** (Jetpack Compose, Room/SQLDelight, Coroutines). Đọc kèm cổng: [backend](../backend/GATES.md), [database](../database/GATES.md), [network](../network/GATES.md), [mobile](../mobile/GATES.md).

## Tổ chức module và khóa ranh giới

- **Backend:** tách theo Gradle/Maven multi-module hoặc theo package gốc của từng miền (`domain`, `application`, `adapter.in.web`, `adapter.in.worker`, `adapter.out.persistence`, `adapter.out.client`, `config`). Dùng **ArchUnit** (Java/Kotlin) hoặc **Konsist** (Kotlin) viết thành unit test để tự động chặn `domain` import `org.springframework.*`, `jakarta.persistence.*`, hoặc thư viện HTTP.
- **Android / KMP:** tách module `:app` (khung khởi động, DI, navigation), `:feature:*` (màn hình + ViewModel, cấm hai `:feature:*` phụ thuộc chéo), `:core:domain`, `:core:database` (Room/SQLDelight + outbox), `:core:network`, `:core:ui`.

## Ràng buộc bắt buộc (BLOCK)

- **Đúng đắn của `@Transactional` (Spring / Jakarta):**
  - Không gọi hàm `@Transactional` từ một hàm khác trong cùng class (`this.method()`) vì lời gọi không đi qua proxy.
  - Mặc định Spring chỉ rollback với `RuntimeException` và `Error`; nếu luồng ném checked exception thì phải khai `rollbackFor = Exception.class`.
  - Tắt `spring.jpa.open-in-view=false` để không giữ kết nối DB suốt thời gian serialize JSON hoặc gọi mạng ngoài.
- **Đồng thời có cấu trúc (Virtual Threads & Kotlin Coroutines):**
  - Trên Kotlin (Ktor / Spring / Android): dùng `Structured Concurrency` (`coroutineScope`, `supervisorScope`, `viewModelScope`), tuyệt đối không phóng `GlobalScope.launch`. Khi `catch (e: Exception)` trong coroutine, phải `if (e is CancellationException) throw e` để không làm gãy cơ chế hủy.
  - Trên Java 21+ Virtual Threads: tránh giữ khóa `synchronized` bao quanh lời gọi mạng/DB dài (gây pinning trên JDK cũ) — ưu tiên `ReentrantLock` và giới hạn đồng thời bằng `Semaphore`.
- **Validation và bất biến:** validate DTO biên bằng Jakarta Bean Validation (`@Valid`) hoặc constructor kiểm tra bất biến của Kotlin value/data class; dùng `BigDecimal` (kèm `RoundingMode` rõ ràng) hoặc `Long` đơn vị nhỏ nhất cho tiền tệ, không dùng `Double`/`Float`.
- **Bảo mật thiết bị (Android):** token phiên nằm trong kho mã hóa dựa trên Android Keystore, không lưu trần trong `SharedPreferences` hay `DataStore` thường.

## Lệnh kiểm chứng chuẩn cho G2

- Gradle: `./gradlew check` (gồm test, Detekt / Ktlint / SpotBugs) và `./gradlew assemble`
- Maven: `./mvnw verify`
- Test tích hợp Backend: JUnit 5 + Testcontainers cho truy vấn/migration thật; ArchUnit/Konsist cho ranh giới module

## Cờ đỏ khi soát G3

- Trả thẳng JPA `@Entity` ra HTTP response (lộ cột nội bộ, gây vòng lặp serialize hoặc nổ truy vấn N+1 do lazy-loading).
- Dùng `equals`/`hashCode` sinh toàn bộ cột của Kotlin `data class` cho JPA `@Entity` có trạng thái khả biến và quan hệ lazy.
- Trên Android: giữ tham chiếu `Activity` / `View` / `Context` ngắn hạn trong singleton hoặc ViewModel gây rò bộ nhớ.
- Khởi tạo `OkHttpClient` / `WebClient` / `RestClient` mới trên từng lời gọi thay vì chia sẻ pool có cấu hình connect/read/call timeout.
