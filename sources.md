# Nguồn và phần tinh chỉnh

Khảo sát trên GitHub, tháng 11/2026. Bộ này là bản viết lại độc lập để dùng khi làm phần mềm, không phải bản sao của repo nguồn, và không gắn với một codebase có sẵn.

## Giữ lại

| Nguồn | Phần lấy |
| --- | --- |
| [github/awesome-copilot — harness-engineering](https://github.com/github/awesome-copilot/blob/main/skills/harness-engineering/SKILL.md) | Công thức Instructions + Constraints + Feedback + Memory + Evaluation + Governance. Failure memory có mục phát hiện. Kiểm tra phải chạy được, hẹp, ít dương tính giả. |
| [leonkoellerwirth-arch/agentic-engineering-standard](https://github.com/leonkoellerwirth-arch/agentic-engineering-standard) | Tách mặt phẳng kiểm chứng khỏi mặt phẳng viết code. Trong bộ này đó là cổng G3: lượt hai tự chạy lệnh. |
| [MartinKChen/harness-claude-code](https://github.com/MartinKChen/harness-claude-code) | Spec là hợp đồng. Cặp người làm / người soát. Tách pattern backend và frontend. Vòng đời feature → kiểm tra. |
| [jordimarsal/harness](https://github.com/jordimarsal/harness) | Cổng trước khi đánh dấu xong. Vai trò spec, implement, review. |
| [romabeckman/harness-kit — developer-backend](https://github.com/romabeckman/harness-kit/blob/main/agents/developer-backend.md) | Checklist backend tối thiểu: test, validate biên, lỗi tường minh, không secret cứng, migration có đường lùi, log, phân quyền. |
| [rendyspratama/backend-things](https://github.com/rendyspratama/backend-things) | Bản đồ thứ phải có trước khi backend chịu tải: yêu cầu, sơ đồ, domain, API, dữ liệu, vận hành. |
| [study8677/awesome-architecture — mobile-app](https://github.com/study8677/awesome-architecture/blob/main/en/templates/mobile-app/README.md) | Lớp UI đọc state cục bộ, DB máy là bản địa, outbox, BFF, push. |
| [martinholovsky/sota-skills — sota-mobile](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-mobile/rules/03-offline-background-push.md) | Khai báo tư thế offline. Outbox bền, idempotency key, conflict theo từng entity, rollback nhìn thấy được. |
| [first-fluke/oh-my-agent — oma-mobile checklist](https://github.com/first-fluke/oh-my-agent/blob/main/skills/oma-mobile/resources/checklist.md) | Token trong secure storage. Trạng thái loading / error / offline. Invalidate đúng query sau mutation. |
| [devkodeio/frontend-system-design](https://github.com/devkodeio/frontend-system-design) | Chọn nền tảng, người dùng, responsive hay adaptive, trước khi vẽ component. |
| [ryanthedev/systems-design.skill — checklists](https://github.com/ryanthedev/systems-design.skill/blob/main/skills/distributed-systems-design/references/checklists.md) | Câu hỏi phạm vi, ước lượng QPS/storage/bandwidth, tín hiệu để thêm cache/queue/shard, cờ đỏ SPOF và consistency. |
| [martinholovsky/sota-skills — sota-databases](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-databases/SKILL.md) | Index khớp truy vấn đã biết. Transaction ngắn. Mọi ghi có thể retry đều idempotent. DDL khóa có chủ đích. |
| [sigmadigitalza/engineering-playbook — database-review](https://github.com/sigmadigitalza/engineering-playbook/blob/main/docs/playbooks/database-review.md) | Expand / backfill / contract. `CREATE INDEX CONCURRENTLY`. `lock_timeout`. Backfill theo lô, tách khỏi DDL. |
| [baelfyre/orchestra — DATABASE_CHECKLIST](https://github.com/baelfyre/orchestra/blob/main/skills/chronicler/DATABASE_CHECKLIST.md) | Constraint, tenant trong khóa, ORM khớp schema, cô lập transaction. |
| [akovalion/paranoid-qa — backend testing](https://github.com/akovalion/paranoid-qa/blob/main/skills/testing/references/backend.md) | Idempotency khi timeout rồi gửi lại. Khuếch đại retry. Client timeout và ngân sách server. |

## Bỏ ngoài bộ này

| Nguồn / ý | Lý do để ngoài |
| --- | --- |
| Workflow script, nhãn GitHub, roster agent của harness-claude-code | Gắn một vòng đời agent và một stack (FastAPI, React, Postgres, Playwright). Bộ này giữ cổng và hợp đồng, bỏ máy điều phối. |
| Catalogue pattern FastAPI / React / Alembic | Gắn một framework. Cổng trong bộ này dừng ở bất biến, để project đích chọn thư viện. |
| Kịch bản phỏng vấn 45 phút trong systems-design.skill | Giữ câu hỏi phạm vi, ước lượng, và tín hiệu chọn thành phần. Bỏ nhịp "interviewer". |
| Sản phẩm CI tên Harness (harness.io) | Khác nghĩa với harness làm phần mềm ở đây. |
| Bộ rule theo từng framework mobile (Riverpod, SwiftData, TanStack) | GATES mobile giữ bất biến. Thư viện nằm trong quyết định của design note. |

## Rule, skill, MCP

| Nguồn | Phần lấy | Để ngoài |
| --- | --- | --- |
| [awesome-copilot harness-engineering](https://github.com/github/awesome-copilot/blob/main/skills/harness-engineering/SKILL.md) | Skill `run-harness` và `review-harness`: brief, bằng chứng, lượt soát đối lập, failure memory | Script drift và file Copilot riêng |
| [awesome-copilot skills](https://github.com/github/awesome-copilot/blob/main/docs/README.skills.md) | Skill là thư mục có `SKILL.md`, nạp khi việc khớp mô tả | Hàng trăm skill không thuộc sáu domain |
| [proyecto26/system-design-skills](https://github.com/proyecto26/system-design-skills/blob/main/skills/system-design/SKILL.md) | Vòng phạm vi → ước lượng → sơ đồ → đánh đổi → cách hỏng. Bảng giải quyết / làm xấu / đổi khi nào | Nhịp phỏng vấn 45 phút và 21 building-block riêng |
| [suleyman/fullstack-agent-skills](https://github.com/suleyman/fullstack-agent-skills) | API sở hữu dữ liệu, trạng thái UI đủ, thay đổi API cộng thêm cho client cũ | Khóa Next.js, FastAPI, Expo |
| [sota-databases](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-databases/SKILL.md) | Hai chế độ làm mới và soát. Index theo truy vấn. Migration expand/contract | Mặc định mọi việc là Postgres hoặc vector DB |
| [enterprise resilience](https://github.com/bricerising/enterprise-software-playbook/blob/main/skills/resilience/SKILL.md) và [sota resilience](https://github.com/martinholovsky/sota-skills/blob/main/skills/sota-architecture/rules/04-resilience-and-failure-design.md) | Thứ tự timeout, idempotency, retry, breaker, trần đồng thời | Con số retry cứng của một thư viện |
| [mobile-architecture](https://github.com/amritmalla/claude-full-stack-2.0/blob/HEAD/skills/architecture/mobile-architecture/SKILL.md) | App là hệ phân tán bị ràng buộc. Chọn nền tảng là quyết định, không phải mặc định | SDK của từng hãng |
| [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) | Reference server nào còn duy trì, server nào đã archive | `@modelcontextprotocol/server-postgres` và GitHub MCP cũ |
| [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | Khối `mcp.json` cho log mạng và trace frontend | Tự bật server lúc mở harness |
| [microsoft/postgres-mcp](https://github.com/microsoft/postgres-mcp) | Lệnh `run` không nhúng mật khẩu. Profile read-only | DSN trong file |
| [Cursor rules](https://github.com/slava-kudzinau/cursor-guide/blob/main/docs/01-fundamentals-core-concepts/02-environment-project-setup.md) | `.mdc` với `description` và `alwaysApply: false` để agent tự chọn | Rule luôn bật cho mọi file |
| [cc-agent-harness](https://github.com/KwokJay/cc-agent-harness) | Rule ngắn, skill ở đường Cursor nạp, MCP merge từng server | Đóng gói CLI nặng phụ thuộc runtime |
| [adobe/ai-repo-harness-guide](https://github.com/adobe/ai-repo-harness-guide), [pt9912/a-check](https://github.com/pt9912/a-check), [anma-labs/anma](https://github.com/anma-labs/anma) | Kiến trúc là đồ thị phụ thuộc một chiều giữa các module; cưỡng bức bằng linter/compiler thay vì nhắc miệng | Khóa cứng một công cụ quét duy nhất |
| [softspark/ai-toolkit](https://github.com/softspark/ai-toolkit), [DongkuKim/dk-harness](https://github.com/DongkuKim/dk-harness), [Ecro/harness-maker](https://github.com/Ecro/harness-maker) | Tách cổng chung khỏi hồ sơ ngôn ngữ (`languages/*.md`), tự dò manifest repo đã có và nạp rule theo `globs` đuôi file | Sinh hàng chục agent persona trùng lặp |

## Cách tinh chỉnh

- Ba tầng tách bạch: **Cổng hành vi (`GATES.md`)** + **Bản đồ module một chiều trong từng domain** + **Hồ sơ ngôn ngữ nạp theo manifest/đuôi file (`languages/*.md` & `harness-lang-*.mdc`)**.
- Không ép dự án mới hay cũ vào một ngôn ngữ duy nhất; nhưng khi dự án đã dùng ngôn ngữ nào thì khóa đúng trình kiểm kiểu, linter ranh giới module, test runner và cờ đỏ của ngôn ngữ đó.
- Validation ở biên và đọc-lại-sau-ghi là luật. Thư viện cụ thể do project đích chọn và ghi lệnh thật vào change brief.
- System design là cổng quyết định, chạy trước khi mở backend, database, và network.
- Mọi mục BLOCK đòi bằng chứng. Mục chỉ là lời khuyên chung ("code sạch", "SOLID") không đưa vào cổng.
