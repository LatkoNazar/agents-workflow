# `agents-workflow` — AI Engineering Skills & Worktree Dev-Sandbox System

Універсальна система скілів та оркестрації агентів (натхненна воркфлоу **Matt Pocock** та **Sandcastle**), яка встановлюється в будь-який репозиторій через `npx skills add` і працює в **Claude Code, Codex, Antigravity та Cursor** через єдиний стандарт `.agents/`.

---

## ⚡ Швидкий старт: Як цим користуватися

### Крок 1. Встановити скіли у свій проект
Відкрий термінал у корені твого проекту та виконай:
```bash
# Встановити всі скіли з репозиторію
npx skills add https://github.com/LatkoNazar/agents-workflow

# Або встановити тільки базовий набір:
npx skills add https://github.com/LatkoNazar/agents-workflow --skill init-agents
```

### Крок 2. Перша ініціалізація (`/init-agents`)
Відкрий чат будь-якого агента (**Claude Code, Codex CLI, Cursor, Antigravity**) та введи:
```text
/init-agents
```
Агент:
1. Дослідить стек твого проекту (бекенд, фронтенд, БД, docker-compose).
2. Задасть 4 короткі питання по `grill-me` (з готовими рекомендованими відповідями `➡️ Recommended`).
3. Згенерує структуру `.agents/` зі скриптами Docker-клонування БД, worktree-сандбоксами та налаштує захисні хуки для всіх агентів.

### Крок 3. Щоденна розробка фіч (покроковий цикл)
Коли починаєш нову фічу, викликай скіли по черзі прямо в чаті:

1. **Узгодження деталей та архітектури (без галюцинацій):**
   ```text
   /grill-me I want to add Stripe subscription billing
   ```
   *Агент опитає тебе раундами по 1–2 питання з варіантами рішень, доки всі крайові випадки не будуть узгоджені.*

2. **Генерація структурованої специфікації (PRD):**
   ```text
   /to-spec
   ```
   *Створює PRD: User Stories, публічні фасади модулів, API контракти, тестові шви та Out of Scope.*

3. **Нарізка на вертикальні тікети (Tracer Bullets):**
   ```text
   /to-tickets
   ```
   *Ділить задачу не горизонтальними шарами, а наскрізними вертикальними зрізами (`DB -> Facade -> Contract -> UI -> Integration Test`) із графом залежностей.*

4. **Реалізація у захищеному сандбоксі:**
   ```text
   /implement 001-stripe-webhook
   # або для виконання всіх незаблокованих тікетів:
   /implement --all
   ```
   *Агент підніме чистий Git worktree + клон твоєї dev-бази даних, напише код за суворим TDD, пройде рев'ю в чистому вікні, запустить `verify.sh` і зільє гілку.*

---

## 2. Каталог скілів (`skills/`) та правил (`rules/`)

При вводі `/` у будь-якому агенті (Codex, Claude Code, Cursor, Antigravity) відображаються **виключно інтерактивні команди для розробника**. Усі технічні стандарти коду та перевірки винесені у внутрішні правила (`rules/`) і діють під капотом, не засмічуючи меню автокомпліту.

### 🟢 Інтерактивні сліш-команди для розробника (`skills/`)
| Скіл (сліш-команда) | Підпис в автокомпліті | Призначення |
| :--- | :--- | :--- |
| **`/init-agents`** | `Scaffold .agents/ workflow: setup Docker sandboxes, worktrees, multi-agent hooks, sub-agents, and AGENTS.md` | Первинне сканування проекту, опитування `grill-me` та генерація всієї агентської інфраструктури. |
| **`/grill-me [idea]`** | `Interview me on requirements & architecture before coding (1-2 questions per round with recommendations)` | Узгодження архітектури та крайових випадків без галюцинацій. |
| **`/to-spec [spec-name]`** | `Synthesize grill-me decisions into a structured PRD with Deep Module facades, contracts & test seams` | Зведення відповідей у повноцінний PRD специфікації. |
| **`/to-tickets [spec.md]`**| `Decompose PRD into Vertical-Slice (Tracer Bullet) tickets with blocked_by DAG dependencies` | Нарізка наскрізних вертикальних тікетів (`DB -> Facade -> UI -> Test`). |
| **`/implement <ticket-id>\|--all`**| `Implement ticket(s) in isolated Git worktree with Docker dev sandbox, TDD & code review` | Повний цикл реалізації в ізольованому worktree + сандбоксі. |
| **`/antislop`** | `Anti-Slop Delivery Gate: blocks AI visual cliches, dead buttons, buzzwords & messy code` | Фільтр проти ШІ-шаблонів, пустих кнопок та сміттєвого коду. |
| **`/ui-from-reference <reference.png>`** | `Build UI 1:1 from screenshot using 0..100% coordinate grid & parallel cluster sub-agents` | Перенесення UI піксель-в-піксель за сіткою та кластерами. |
| **`/design-an-interface <module-name>`** | `Design It Twice: explore competing Deep Module facade interfaces before implementation` | Створення двох конкуруючих архітектур фасаду. |
| **`/security-audit [endpoint-or-pr]`** | `Security audit & trust boundary check: hunt for IDOR, auth bypass, race & injection bugs` | Пошук вразливостей на межах довіри (OWASP/Cloudflare). |
| **`/diagnosing-bugs <bug-or-error>`** | `Reproduce and fix bugs with a failing test inside isolated worktree & cloned dev DB` | Відтворення бага падаючим тестом у worktree-сандбоксі. |
| **`/improve-architecture [module]`** | `Audit codebase architecture: detect shallow horizontal layers and refactor into deep modules` | Аудит та рефакторинг роздутих шарів у глибокі модулі. |
| **`/handoff [next-focus]`** | `Save clean session state to a handoff file so you can /clear and keep <100k Smart Zone` | Збереження вижимки перед очищенням контексту. |
| **`/find-skills <stack-or-topic>`** | `Search & install official skills for your stack (React, Next.js, FastAPI, etc.)` | Пошук зовнішніх скілів з екосистеми skills.sh під ваш стек. |

### ⚙️ Внутрішні правила агентів (`rules/` — діють автоматично під капотом)
Ці стандарти вшиті в системні промпти відповідних ролей у `.agents/agents/` та виконуються автономно:
| Правило | Роль, яка застосовує | Що робить |
| :--- | :--- | :--- |
| **`codebase-design.md`** | `implementer`, `reviewer` | Архітектурний стандарт Deep Modules: вузькі публічні фасади (`facade.*`, `index.*`), приховані нутрощі (`internal/`), висока локальність. |
| **`tdd.md`** | `implementer` | Суворий цикл Red-Green-Refactor проти реальної БД у сандбоксі перед написанням коду. |
| **`ddd.md`** | `reviewer`, `tester` | Doubt-Driven Development: презумпція сумніву, пошук race conditions, дедлоків та крайових випадків у чистому контексті. |
| **`code-review.md`** | `reviewer` | Двохосьове рев'ю: повнота вертикального зрізу за ТЗ + архітектурні межі модулів. |
| **`sync-contracts.md`** | `implementer`, `merger` | Автоматичний контрактний синк між бекендом (OpenAPI) та фронтендом (TypeScript) при кожній зміні DTO/API. |
| **`code-simplification.md`** | `reviewer`, `implementer` | Спрощення та вирівнювання коду: видалення зайвих шарів абстракції та бойлерплейту після проходження тестів. |

---

## 3. Структура `.agents/` після ініціалізації

Після виконання `/init-agents` у проекті з'являється структурована директорія `.agents/`:
```text
.agents/
├── workflow.json              # Конфіг Kanban, Docker-клонування, моделей та шаблонів оркестрації
├── agents/
│   ├── explorer.md            # Швидкий субагент розвідки коду (контракти без реалізації)
│   ├── implementer.md         # Будівник вертикальних зрізів за суворим TDD
│   ├── tester.md              # Субагент верифікації (екранує логи, визначає blast radius)
│   ├── reviewer.md            # Рев'юер у чистому контексті із зашитими правилами проекту
│   ├── merger.md              # Інтегратор гілок та очищувач сандбоксів
│   ├── security-auditor.md    # Спеціаліст безпеки (IDOR, Auth, ін'єкції, вебхуки, витік секретів)
│   └── web-performance-auditor.md # Спеціаліст швидкодії (Core Web Vitals, Lighthouse, DevTools MCP)
├── scripts/
│   ├── worktree-up.sh         # Git worktree + повний клон Postgres, Mongo, Redis, Volumes, профілів
│   ├── worktree-down.sh       # Знесення клонованого сандбоксу + видалення worktree
│   ├── verify.sh              # Єдиний контур: Boundary check -> Backend tests -> Contract sync -> Frontend tsc/tests
│   ├── lint-ui.sh             # Опціональний детермінований UI-лінтер токенів та анти-слопу
│   ├── ui-ref.py              # Накладання координатної сітки 0..100% та кропінг кластерів
│   ├── setup-hooks.sh         # Автоналаштування хуків для Claude Code, Codex, Gemini, Cursor
│   ├── hook-pre-bash.sh       # PreToolUse: блокування деструктивних дій та ask на git push
│   ├── hook-stop-verify.sh    # Stop-гейт: автоперевірка verify.sh --affected перед завершенням
│   └── afk-loop.sh            # Автономний термінальний ранер (single / sequential / parallel DAG)
├── specs/                     # PRD документи (при local Kanban)
└── tickets/                   # Вертикальні тікети з blocked_by (при local Kanban)
```

---

## 4. Нічна зміна: Автономний ранер у терміналі (AFK Loop)

Якщо ви хочете запустити реалізацію тікетів автономно без постійного сидіння в чаті:
```bash
# Реалізувати один конкретний тікет:
./.agents/scripts/afk-loop.sh 001-tracer-bullet

# Запустити автоматичне виконання всіх незаблокованих AFK-тікетів:
./.agents/scripts/afk-loop.sh --all
```
Ранер послідовно або паралельним графом підніматиме worktree, клонуватиме Docker dev-стан, ганятиме тести й рев'ю, та зливатиме гілки.

---

## 5. Крос-агентні запобіжники та хуки

Система автоматично підтримує роботу в **Claude Code**, **OpenAI Codex CLI**, **Gemini CLI / Antigravity** та **Cursor** без потреби дублювати файли налаштувань вручну.

### Єдиний стандарт інструкцій: `AGENTS.md`
- Усі сучасні кодинг-агенти підтримують стандарт `AGENTS.md` у корені репозиторію.
- `CLAUDE.md` більше не потрібен як дублікат.
- Файл `AGENTS.md` тримається **до 100 рядків** для збереження сесії в межах **Smart Zone (<100k токенів)**.

### Нативні запобіжники (`setup-hooks.sh`)
При виконанні `/init-agents` або при кожному виклику `verify.sh`, скрипт `setup-hooks.sh` автоматично перевіряє та підключає конфігурації для всіх 4 середовищ одночасно:
- `.claude/settings.json` (Claude Code)
- `.codex/hooks.json` (Codex CLI)
- `.gemini/settings.json` (Gemini CLI / Antigravity)
- `.cursor/hooks.json` (Cursor)

#### Що контролюють хуки:
1. **Жорстке блокування (`deny`):**
   - `git push --force` / `-f` / `--force-with-lease`
   - `git reset --hard`
   - `git clean -f`
   - Спроба застейджити секрети: `git add .env*` (дозволено лише `.env.example`/`.template`)
   - `rm -rf` за межами поточної робочої директорії
2. **Контроль людини на звичайний пуш (`ask`):**
   - На будь-яку спробу `git push` агент обов'язково запитує підтвердження користувача, тому ви завжди особисто контролюєте, що і коли летить у віддалений репозиторій.
3. **Stop-гейт («Турнікет на виході»):**
   - Перед завершенням ходу агента хук автоматично запускає `./.agents/scripts/verify.sh --affected`. Якщо агент змінив код і зламав тести або тайпчек, хід блокується з виведенням помилки, спонукаючи агента негайно виправити регресію.
