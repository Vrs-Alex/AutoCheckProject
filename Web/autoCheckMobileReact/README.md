# AutoCheckMobile Web Dashboard

Веб-интерфейс эксперта для командного задания AutoCheckMobile: создание тестовых заданий, загрузка решений кандидатов, просмотр статусов автопроверки, AI-анализ и итоговый вердикт.

## Стек

- React + Vite + TypeScript
- Redux Toolkit
- RTK Query для всех API-запросов
- Реальный backend AutoCheck через `/api/v1`; MSW оставлен только как optional fallback
- Tailwind CSS v4
- React Router
- Recharts
- Inline SVG icons без внешнего icon pack

## Запуск

```bash
npm install
npm run dev
```

По умолчанию web работает с реальным backend на `localhost:8080` через Vite proxy. Откройте адрес из терминала, обычно `http://localhost:5173`.

Перед запуском backend:

```bash
cd ../AutoCheckMobile-backend/Backend/auth-check
docker compose up -d --build
```

## Docker

Веб можно запускать как отдельный контейнер. Внутри Docker-сети nginx проксирует `/api` на сервис `backend:8080`.

```bash
docker build -t autocheck-web .
docker run --rm -p 5173:80 autocheck-web
```

Для полного стенда удобнее использовать общий репозиторий `allTogether`: он поднимает `web`, `backend`, `worker`, PostgreSQL, Redis и checker image одной командой.

## Демо-пользователи

```text
Эксперт:
email: expert@autocheck.local
password: secret123

Кандидат:
email: candidate@autocheck.local
password: secret123
```

Если база свежая, нажмите в форме входа `Создать пользователя`: frontend вызовет настоящий `POST /api/v1/auth/register`, сохранит JWT и откроет dashboard.

## Backend / fallback

MSW стартует в `src/main.tsx` только если `VITE_USE_MOCKS=true`.

```env
VITE_USE_MOCKS=false
VITE_API_URL=/api/v1
```

`/api` проксируется Vite dev server-ом на `http://localhost:8080`, поэтому браузер не упирается в CORS.

Чтобы включить старые моки:

```env
VITE_USE_MOCKS=true
VITE_API_URL=/api/v1
```

Backend API приведён к Swagger-контракту и возвращает обертку `{ data, error, meta }`. `baseApi` снимает эту обертку один раз, а RTK Query endpoints получают уже чистые DTO. UI внутри использует удобные frontend-модели, но RTK Query на границе нормализует backend-поля:

- `role: EXPERT/CANDIDATE` → `expert/candidate`
- `checkerWeights` → `checkerConfig`
- `candidateFullName` → `candidateName`
- `status: PENDING/RUNNING/DONE/ERROR` → `pending/running/passed/failed/error`
- `totalScore` → `score`
- `verdict: ACCEPTED/REJECTED/null` → `accepted/rejected/none`
- `error.details` → `error.fields`

Успешный ответ backend выглядит так:

```json
{
  "data": {
    "id": "s1",
    "assignmentTitle": "Flutter Auth Screen",
    "candidateFullName": "Иван Петров",
    "status": "DONE",
    "totalScore": 78
  }
}
```

Ошибки:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Проверьте поля формы",
    "details": {
      "email": "Некорректный email"
    }
  }
}
```

## API endpoints

UI подключён к реальным endpoint-ам backend:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/profile`
- `GET /api/v1/assignments`
- `POST /api/v1/assignments`
- `GET /api/v1/assignments/:id`
- `POST /api/v1/submissions`
- `GET /api/v1/submissions`
- `GET /api/v1/submissions/:id`
- `GET /api/v1/submissions/:id/status`
- `GET /api/v1/submissions/:id/results`
- `POST /api/v1/submissions/:id/rerun`
- `PUT /api/v1/submissions/:id/verdict`
- `GET /api/v1/submissions/:id/ai-review`
- `GET /api/v1/submissions/:id/report`
- `GET /api/v1/candidates`
- `GET /api/v1/candidates/:id`
- `GET /api/v1/reports/stats`

В UI есть локальная timeline-секция; отдельного `/api/v1/submissions/:id/timeline` в Swagger нет, поэтому timeline вычисляется из `Submission.createdAt/completedAt/status/verdict` на клиенте.

## Экраны

- `/login` — вход с демо-логинами и validation/API errors.
- `/dashboard` — KPI, поиск, фильтры, таблица проверок, status badges.
- `/submissions/new` — загрузка ZIP до 50 МБ или Git URL.
- `/submissions/:id` — ScoreCard, чекеры, AI-анализ, timeline, verdict dialog.
- `/assignments/new` — создание задания, чекеры, слайдеры весов, контроль суммы 100%.
- `/statistics` — метрики, line chart за 30 дней, топ-10 кандидатов.

## Архитектура

```text
src/
  app/                  Redux store и typed hooks
  shared/api/           baseApi, типы, обработка ошибок
  shared/ui/            общие UI-компоненты
  shared/lib/           форматирование, валидация, helpers
  features/auth/        auth slice + RTK Query endpoints + LoginPage
  features/assignments/ assignment endpoints + CreateAssignmentPage
  features/submissions/ submissions endpoints, filters slice, dashboard/details/upload
  features/reports/     reports endpoint + StatisticsPage
  features/ui/          toast/sidebar UI state
  layouts/              AppLayout, Sidebar, Topbar
  mocks/                MSW handlers, seed data, in-memory db
```

Правило проекта: server data хранится в RTK Query cache, локальное состояние фильтров и оболочки хранится в Redux slices, компоненты не вызывают `fetch` напрямую.

## Проверка состояний

- Loading: открыть любую страницу после refresh или на медленном Docker backend.
- Error 422/400: ввести неверные логин/пароль или отправить форму с пустыми полями.
- Empty: включить несколько фильтров на дашборде до отсутствия результатов.
- AI fallback: карточка проверки показывает `AI-анализ недоступен`, если backend не вернул AI summary.
- Progress: после загрузки нового решения статус обновляется через polling `pending → running → passed/failed/error`.
