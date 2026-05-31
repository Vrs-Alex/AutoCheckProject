# AutoCheckMobile — Backend

Платформа автоматической проверки тестовых заданий мобильных разработчиков.  
Конкурсный проект чемпионата «Профессионалы» 2026, г. Нижний Новгород.

---

## Архитектура системы

```
┌─────────────────────────────────────────────────────────────────┐
│                        Клиенты                                  │
│   Web Dashboard (Эксперт)        Mobile App / Flutter (Кандидат)│
└──────────────┬──────────────────────────────┬───────────────────┘
               │ REST API                      │ REST API
               ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Backend API  :8080                           │
│  Spring Boot 3 + Kotlin  ·  JWT Auth  ·  OpenAPI / Swagger     │
│                                                                 │
│  AuthController  AssignmentController  SubmissionController     │
│  CandidateController  ReportController                          │
└──────────┬──────────────────────────────────┬───────────────────┘
           │ JPA                              │ BLPOP
           ▼                                  ▼
┌──────────────────┐              ┌──────────────────────────────┐
│   PostgreSQL 16  │              │          Redis 7             │
│  users           │              │  submission:queue (FIFO)     │
│  assignments     │              │  jwt:blacklist               │
│  submissions     │              └──────────────┬───────────────┘
│  check_results   │                             │ dequeue
└──────────────────┘              ┌──────────────▼───────────────┐
                                  │          Worker              │
                                  │  SubmissionWorkerService     │
                                  │  CheckOrchestrator           │
                                  └──────────────┬───────────────┘
                                                 │ docker run
                          ┌──────────────────────▼───────────────────────┐
                          │         Checker Containers (изолированно)    │
                          │                                               │
                          │  ┌──────────┐ ┌──────┐ ┌──────────────────┐ │
                          │  │ StaticAn.│ │ Arch.│ │ Build / Tests    │ │
                          │  │ --mem    │ │ --mem│ │ --mem 512m       │ │
                          │  │ 512m     │ │ 512m │ │ --cpus 1         │ │
                          │  └──────────┘ └──────┘ └──────────────────┘ │
                          │  Каждый: autocheck-checker:latest            │
                          │  Таймаут: 3 минуты · Результат → JSON stdout │
                          └───────────────────────────────────────────────┘
```

---

## Стек технологий

| Компонент | Технология |
|---|---|
| Backend | Spring Boot 3.4.5, Kotlin, Java 21 |
| База данных | PostgreSQL 16 |
| Очередь / кэш | Redis 7 |
| Миграции | Flyway |
| Аутентификация | JWT (jjwt), Redis blacklist |
| Контейнеризация | Docker, Docker Compose |
| Checker-контейнеры | eclipse-temurin:21-jdk-alpine + Python 3 + git |
| API документация | SpringDoc OpenAPI (Swagger UI) |
| Сериализация | Jackson (NON_NULL, ISO-8601 даты) |

---

## Роли пользователей

| Роль | Возможности |
|---|---|
| **EXPERT** | Создаёт задания, настраивает веса чекеров, просматривает все проверки, выносит вердикт ACCEPTED/REJECTED |
| **CANDIDATE** | Загружает решение (ZIP или Git URL), просматривает только свои проверки |

---

## Движок автоматической проверки

После загрузки решения задача помещается в Redis-очередь. Worker извлекает её и запускает **каждый чекер в отдельном Docker-контейнере**:

| Чекер | Что проверяет | Метрика |
|---|---|---|
| `STATIC_ANALYSIS` | TODO/FIXME, пустые catch, длинные строки, print-statements | `100 - errors×5 - warnings×1` |
| `ARCHITECTURE` | Наличие слоёв domain/presentation/data/infrastructure | `+25` за каждый слой |
| `BUILD` | Сборка проекта (Gradle / Flutter / Maven) | 100 при успехе, 0 при ошибке |
| `TESTS` | Запуск unit-тестов, парсинг JUnit XML | `passed / total × 100` |
| `DOCUMENTATION` | README.md, KDoc/JavaDoc комментарии, логирование | взвешенная сумма |
| `GIT_PRACTICES` | История коммитов, качество сообщений, ветки | взвешенная сумма |

Итоговый балл: `Σ(score_i × weight_i) / Σ(weight_i)`

Каждый чекер:
- Запускается в изолированном контейнере (`autocheck-checker:latest`)
- Ограничен 512 МБ RAM и 1 CPU
- Принудительно завершается через **3 минуты**
- Отказ одного чекера не останавливает остальных

---

## Формат API

Все ответы обёрнуты в единый конверт:

```json
// Успех
{"data": {"id": 1, "email": "expert@company.com"}}

// Ошибка
{"error": {"code": "NOT_FOUND", "message": "Задание 5 не найдено"}}

// Ошибки валидации (422)
{"error": {"code": "VALIDATION_ERROR", "message": "Ошибка валидации",
  "details": {"email": "Некорректный email"}}}
```

Swagger UI: `http://localhost:8080/api/swagger-ui.html`  
OpenAPI JSON: `http://localhost:8080/api/docs`

---

## Быстрый старт (локально)

### Зависимости
- Docker и Docker Compose

### Запуск

```bash
git clone <repo-url>
cd auth-check

cp .env.example .env
# При необходимости отредактируй .env

sudo docker compose up --build -d
```

Сервис будет доступен на `http://localhost:8080`.

### Остановка

```bash
sudo docker compose down
```

---

## Переменные окружения

Создай файл `.env` в корне проекта (см. `.env.example`):

| Переменная | Описание | По умолчанию |
|---|---|---|
| `DB_USERNAME` | Пользователь PostgreSQL | `postgres` |
| `DB_PASSWORD` | Пароль PostgreSQL | `postgres` |
| `JWT_SECRET` | Секрет для подписи JWT (мин. 32 символа) | небезопасный дефолт |
| `AI_API_KEY` | API ключ для LLM (OpenAI-совместимый) | пусто |
| `AI_BASE_URL` | Base URL LLM API | `https://api.openai.com` |
| `APP_URL` | Публичный URL сервиса | `http://localhost:8080` |
| `UPLOADS_DIR` | Директория для ZIP файлов | `/app/uploads` |
| `DOCKER_UPLOADS_VOLUME` | Имя Docker volume с uploads | `auth-check_uploads_data` |
| `CHECKER_IMAGE` | Docker образ для чекеров | `autocheck-checker:latest` |

---

## Развёртывание на VPS / облаке

```bash
# 1. Клонируй репозиторий на сервер
git clone <repo-url>
cd auth-check

# 2. Заполни переменные окружения
cp .env.example .env
nano .env  # укажи JWT_SECRET, пароли и т.д.

# 3. Собери и запусти
sudo docker compose up --build -d

# 4. Проверь что всё запущено
sudo docker compose ps
sudo docker compose logs backend --tail=50
```

---

## Структура проекта

```
src/main/kotlin/com/team/auth_check/
├── domain/
│   ├── model/          # Чистые data class: User, Assignment, Submission, CheckResult
│   ├── repository/     # Интерфейсы репозиториев (без Spring/JPA)
│   └── checker/        # IChecker, CheckContext, CheckerResult
├── application/
│   ├── dto/            # DTO запросов/ответов, ApiResponse<T>
│   ├── service/        # AuthService, AssignmentService, SubmissionService и др.
│   └── checker/        # CheckOrchestrator, DockerCheckerRunner, Worker, Queue
├── infrastructure/
│   ├── persistence/    # JPA entities, repositories, mappers
│   ├── security/       # JwtService, JwtAuthFilter, SecurityConfig
│   ├── storage/        # FileStorageService (ZIP save/extract)
│   └── config/         # AppConfig, OpenApiConfig
└── presentation/
    ├── controller/     # 5 REST контроллеров
    └── advice/         # GlobalExceptionHandler

checker-scripts/        # Python-скрипты для checker-контейнеров
checker.Dockerfile      # Образ для checker-контейнеров
Dockerfile              # Образ backend/api
Dockerfile.worker       # Образ worker (+ docker-cli)
docker-compose.yml      # Все сервисы: db, redis, backend, worker, checker-runner
```

---

## CI/CD

GitHub Actions pipeline запускается при каждом пуше:
- Компиляция Kotlin
- Запуск unit-тестов
- Сборка Docker образа

Конфигурация: `.github/workflows/ci.yml`
