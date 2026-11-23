# Python

Áp dụng cho **Backend / API** (FastAPI, Django, Flask, Litestar), **Background Jobs / Workers** (Celery, Dramatiq, Arq, Temporal), và **Data / AI Services**. Đọc kèm cổng: [backend](../backend/GATES.md), [database](../database/GATES.md), [network](../network/GATES.md).

## Tổ chức module và khóa ranh giới

- Dùng bố cục `src/<ten_goi>/` tách rõ vai trò:
  - `domain/`: dataclass / entity thuần, value object, ngoại lệ miền. Không import FastAPI, Django HTTP, SQLAlchemy session, hay `httpx`/`requests`.
  - `application/`: use case, unit-of-work / quản lý transaction, giao diện `Protocol` / `ABC` cho kho lưu trữ và dịch vụ ngoài.
  - `entrypoints/` (`api/`, `workers/`, `cli/`): router, parse schema biên, xác thực/phân quyền, gọi `application`.
  - `adapters/` (`db/`, `clients/`, `outbox/`): ORM models, repository cụ thể, migration (Alembic / Django migrations), HTTP client.
- Khóa chiều phụ thuộc bằng `import-linter` hoặc `tach` để ngăn `domain` và `application` import ngược từ `entrypoints` hoặc `adapters`.

## Ràng buộc bắt buộc (BLOCK)

- **Kiểu tĩnh và khóa phụ thuộc:** quản lý môi trường có file khóa (`uv.lock`, `poetry.lock`, hoặc tương đương). Mọi hàm ở biên module và use case có type annotations đầy đủ, kiểm bằng `pyright` hoặc `mypy --strict`.
- **Schema chặt ở biên:** payload vào/ra qua Pydantic v2 (`model_config = ConfigDict(extra="forbid")` khi cần chặn trường lạ) hoặc serializer kiểm kiểu rõ ràng; không truyền `dict[str, Any]` chưa kiểm vào sâu trong `application`/`domain`.
- **Không làm nghẽn vòng lặp `asyncio`:** trong hàm `async def` (FastAPI, `aiohttp`, worker async), cấm gọi trực tiếp thư viện chặn luồng như `requests`, `time.sleep`, subprocess đồng bộ, hay ORM đồng bộ. Dùng client async (`httpx.AsyncClient` dùng chung có `Timeout`) hoặc đẩy sang threadpool có kiểm soát.
- **Vòng đời DB session rõ ràng:** mỗi request hoặc mỗi lần chạy job tạo và đóng riêng một `Session` / `AsyncSession`. Không giữ session toàn cục dùng chung giữa các request và không truy cập thuộc tính lazy-load sau khi session đã đóng (`expire_on_commit=False` khi cần đọc entity sau commit).

## Lệnh kiểm chứng chuẩn cho G2

- Lint & định dạng: `ruff check .` và `ruff format --check .`
- Kiểm kiểu tĩnh: `pyright` hoặc `mypy .`
- Kiểm ranh giới import (nếu đã cấu hình): `lint-imports` hoặc `tach check`
- Test: `pytest` (kèm `pytest-asyncio` cho luồng async)

## Cờ đỏ khi soát G3

- Giá trị mặc định khả biến trong chữ ký hàm (`def handle(items: list[str] = []):`) làm rò trạng thái giữa các lần gọi.
- `except Exception:` nuốt lỗi hoặc chỉ `logger.error(...)` rồi trả thành công; hoặc bắt `BaseException` nuốt luôn `asyncio.CancelledError`.
- Khởi tạo `httpx.AsyncClient()` mới bên trong từng request thay vì dùng chung qua `lifespan` của ứng dụng (gây rò và cạn kết nối TLS).
- Tác vụ Celery/worker nhận đối tượng ORM hoặc payload lớn thay vì nhận định danh (`id`) kèm `idempotency_key` rồi tự đọc trạng thái mới nhất từ DB.
