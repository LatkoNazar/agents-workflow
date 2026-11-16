# `agents-workflow` — AI Engineering Skills & Worktree Dev-Sandbox System

Універсальна система скілів та оркестрації агентів (натхненна воркфлоу **Matt Pocock** та **Sandcastle**), яка встановлюється в будь-який репозиторій через `npx skills add` і працює в **Claude Code, Codex, Antigravity та Cursor** через стандарт `.agents/`.

---

## Чому ця система працює

1. **Smart Zone (<100k токенів):** Жодних роздутих системних промптів. Виконавець (`implementer`) підтягує скіли за моделлю **Pull**, а рев'юер (`reviewer`) отримує всі правила та стандарти проекту в чистому контексті за моделлю **Push**.
2. **Vertical Slices (Tracer Bullets) замість горизонтальних шарів:** Заборонено робити задачі шарами («спочатку вся БД, потім весь бекенд, потім весь фронт»). Кожен тікет прошиває стек вертикально наскрізь (`DB/State -> Deep Module Facade -> Contract Sync -> Frontend Feature -> Seam Test`) і залишає проект на 100% зеленим після кожної ітерації.
3. **Deep Modules & Gray-Box Testing:** Кожен бізнес-модуль має один вузький публічний фасад (`facade.py` / `facade.ts` / `index.ts`) і приховану реалізацію (`internal/`). Тести пишуться за суворим TDD виключно проти публічного фасаду та реальної клонованої БД (без моків внутрішніх класів чи репозиторіїв).
4. **Git Worktree + Повний Docker-Сандбокс Dev-Оточення:** Агент живе на хості у Git worktree (`.worktrees/wt-<id>`), але під кожен worktree автоматично клонується **повна копія стану твоєї головної dev-апки** (Postgres, MongoDB, Redis, Docker volumes, локальні профілі, юзери, файли та `.env` зі зміщеними портами). Після мерджу весь сандбокс миттєво видаляється.

---

## 1. Встановлення в проект

```bash
# Встановити всі скіли з репозиторію у проект (.agents/skills/)
npx skills add https://github.com/LatkoNazar/agents-workflow

# Або встановити точково конкретні скіли:
npx skills add https://github.com/LatkoNazar/agents-workflow --skill init-agents
npx skills add https://github.com/LatkoNazar/agents-workflow --skill find-skills
npx skills add https://github.com/LatkoNazar/agents-workflow --skill grill-me
npx skills add https://github.com/LatkoNazar/agents-workflow --skill code-review
```

---

## 2. Каталог скілів (`basic` та `addons`)

### Ядро (`skills/basic/`) — базовий пайплайн для кожного проекту
| Скіл | Призначення |
| :--- | :--- |
| **`/init-agents`** | Сканує проект, опитує тебе по `grill-me`, налаштовує Kanban (`local` / `github` / `trello` / `linear`), генерує `.agents/workflow.json`, скрипти клонування Docker-сандбоксу (`worktree-up.sh`, `worktree-down.sh`, `verify.sh`, `afk-loop.sh`), фокусованих субагентів (`.agents/agents/*.md`) та лаконічний `AGENTS.md`/`CLAUDE.md`. |
| **`/find-skills`** | Пошук та інсталяція зовнішніх скілів з екосистеми `npx skills` (`skills.sh`) під конкретний стек проекту (напр., React, Next.js, Playwright, FastAPI) або під час `/init-agents`. |
| **`/grill-me`** | Безжальне інтерв'ю по дереву рішень: 1–2 питання за раунд із рекомендованим варіантом відповіді (`➡️ Recommended`), доки всі деталі архітектури не узгоджені. |
| **`/antislop`** | Потужний модульний Anti-Slop фільтр та Delivery Gate (об'єднує 40 правил `antislop.ai.id`, `frontend-design` від Anthropic та `web-design-guidelines` від Vercel): блокує візуальні штампи ШІ, пусті кнопки, баззворди, `—` у текстах, сміттєві коментарі в коді та вимагає Empty/Loading/Error стани й відповідність референсу. |
| **`/ui-from-reference`** | Перенесення UI 1-в-1 із картинки-референсу без пропуску дрібних деталей: накладає координатну сітку `0..100%` (`ui-ref.py`), ріже екран на 3–5 великих плям-кластерів, запускає паралельних субагентів (`1 кластер = 1 кроп = 1 файл`) із поштучним чек-листом елементів і звіряє живий рендер у Chrome DevTools по сітці. |
| **`/handoff`** | Заміна `/compact` за принципом «Мементо»: зберігає чисту вижимку без «осаду» в тимчасовий файл, щоб зробити `/clear` і продовжити в межах <100k Smart Zone. |
| **`/to-spec`** | Синтезує результати інтерв'ю у PRD (User Stories, публічні фасади Deep Modules, контракти, межі тестування, Out of Scope). |
| **`/to-tickets`** | Нарізає PRD у граф **Vertical Slices (Tracer Bullets)** із залежностями `blocked_by` та мітками `afk` / `hitl` у вибраний Kanban. |
| **`/tdd`** | Суворий цикл Red -> Green інтеграційними тестами по публічному фасаду модуля проти клонованої сандбокс-БД. |
| **`/ddd`** | **Doubt-Driven Development** (напарник `/tdd`): презумпція сумніву (`CLAIM -> EXTRACT -> DOUBT -> RECONCILE -> STOP`) для перевірки нетривіальних рішень, race conditions, ідемпотентності та граничних станів у чистому вікні з метою спростувати, а не схвалити. |
| **`/code-review`** | Двовісне рев'ю дифу в чистому контексті двома паралельними субагентами: **Spec & Vertical Completeness** + **Pushed Standards & Deep Modules**. |
| **`/implement`** | Виконує тікет (або граф тікетів) в ізольованому worktree + Docker-сандбоксі: `worktree-up.sh -> Implementer (--affected) -> Tester -> Reviewer -> Merger (--full) -> worktree-down.sh`. |
| **`/codebase-design`** | Словник та правила проектування глибоких модулів (Deep Modules, Seams, Locality, Deletion Test). |
| **`/improve-architecture`** | Аудит кодової бази: знаходить горизонтальні шари та мілкі модулі і допомагає об'єднати їх у глибокі вертикальні модулі. |

### Надбудови (`skills/addons/`) — спеціалізовані розширення
| Скіл | Призначення |
| :--- | :--- |
| **`/sync-contracts`** | Зшиває дві мови (напр., Python/Go бекенд + React/TS фронтенд) через єдиний контракт (`openapi.json` / `.proto` -> кодогенерація клієнта та типізованих MSW-моків) у `verify.sh`. |
| **`/diagnosing-bugs`** | Піднімає клон живого dev-оточення у worktree, відтворює баг падаючим тестом на фасаді і фіксить його без ризику зламати основну dev-базу. |
| **`/design-an-interface`** | Принцип «Design It Twice»: запускає паралельних субагентів для проектування радикально різних інтерфейсів фасаду перед вибором найкращого. |
| **`/security-audit`** | Пошук вразливостей на межах довіри (Cloudflare methodology + OWASP/STRIDE): перевірка на IDOR/BOLA, Auth bypass, ін'єкції, race conditions у платежах та витік секретів із відтворенням у клонованому worktree-сандбоксі. |
| **`/code-simplification`** | Спрощення та вирівнювання коду після зелених тестів (flatten nesting, guard clauses, видалення зайвих обгорток) при 100% збереженні поведінки. |

---

## 3. Щоденний воркфлоу

### Крок 0: Ініціалізація в новому або існуючому репозиторії
Запусти в чаті свого AI-агента:
```text
/init-agents
```
Агент дослідить репозиторій, проведе коротке опитування і створить у проекті структуру `.agents/`:
```text
.agents/
├── workflow.json              # Конфіг Kanban, Docker-клонування, моделей та шаблонів оркестрації
├── agents/
│   ├── explorer.md            # Швидкий субагент розвідки коду
│   ├── implementer.md         # Будівник вертикальних зрізів за суворим TDD
│   ├── tester.md              # Субагент верифікації (екранує логи, визначає blast radius)
│   ├── reviewer.md            # Рев'юер у чистому контексті із зашитими правилами проекту
│   └── merger.md              # Інтегратор гілок та очищувач сандбоксів
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

### Денна зміна (Human-in-the-Loop)
1. **Узгодження дизайну:** `/grill-me Хочу додати фічу ...`
2. **Генерація PRD:** `/to-spec`
3. **Нарізка на вертикальні тікети (Tracer Bullets):** `/to-tickets`

### Нічна зміна / Реалізація (Worktree + Docker Sandbox)
- **Прямо в чаті агента (через нативні субагенти):**
  ```text
  /implement 001-tracer-bullet
  # або для всіх незаблокованих AFK-тікетів:
  /implement --all
  ```
- **Або автономним циклом у терміналі:**
  ```bash
  # Один тікет:
  ./.agents/scripts/afk-loop.sh 001-tracer-bullet

  # Усі незаблоковані AFK-тікети (у режимі sequential-with-review або parallel-dag-with-review):
  ./.agents/scripts/afk-loop.sh --all
  ```

---

## 4. Крос-агентні запобіжники та хуки

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
