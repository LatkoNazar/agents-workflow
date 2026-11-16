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
| **`/to-spec`** | Синтезує результати інтерв'ю у PRD (User Stories, публічні фасади Deep Modules, контракти, межі тестування, Out of Scope). |
| **`/to-tickets`** | Нарізає PRD у граф **Vertical Slices (Tracer Bullets)** із залежностями `blocked_by` та мітками `afk` / `hitl` у вибраний Kanban. |
| **`/tdd`** | Суворий цикл Red -> Green інтеграційними тестами по публічному фасаду модуля проти клонованої сандбокс-БД. |
| **`/code-review`** | Двовісне рев'ю дифу в чистому контексті двома паралельними субагентами: **Spec & Vertical Completeness** + **Pushed Standards & Deep Modules**. |
| **`/implement`** | Виконує тікет (або граф тікетів) в ізольованому worktree + Docker-сандбоксі: `worktree-up.sh -> Implementer -> Reviewer -> Merger -> worktree-down.sh`. |
| **`/codebase-design`** | Словник та правила проектування глибоких модулів (Deep Modules, Seams, Locality, Deletion Test). |
| **`/improve-architecture`** | Аудит кодової бази: знаходить горизонтальні шари та мілкі модулі і допомагає об'єднати їх у глибокі вертикальні модулі. |

### Надбудови (`skills/addons/`) — спеціалізовані розширення
| Скіл | Призначення |
| :--- | :--- |
| **`/sync-contracts`** | Зшиває дві мови (напр., Python/Go бекенд + React/TS фронтенд) через єдиний контракт (`openapi.json` / `.proto` -> кодогенерація клієнта та типізованих MSW-моків) у `verify.sh`. |
| **`/diagnosing-bugs`** | Піднімає клон живого dev-оточення у worktree, відтворює баг падаючим тестом на фасаді і фіксить його без ризику зламати основну dev-базу. |
| **`/design-an-interface`** | Принцип «Design It Twice»: запускає паралельних субагентів для проектування радикально різних інтерфейсів фасаду перед вибором найкращого. |

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
│   ├── reviewer.md            # Рев'юер у чистому контексті із зашитими правилами проекту
│   └── merger.md              # Інтегратор гілок та очищувач сандбоксів
├── scripts/
│   ├── worktree-up.sh         # Git worktree + повний клон Postgres, Mongo, Redis, Volumes, профілів
│   ├── worktree-down.sh       # Знесення клонованого сандбоксу + видалення worktree
│   ├── verify.sh              # Єдиний контур: Boundary check -> Backend tests -> Contract sync -> Frontend tsc/tests
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
