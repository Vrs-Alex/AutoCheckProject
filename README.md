# AutoCheckMobile

Платформа автоматической проверки тестовых заданий мобильных разработчиков.  
Конкурсный проект чемпионата «Профессионалы» 2026, г. Нижний Новгород.

---

## Что это такое

AutoCheckMobile — система, которая автоматически проверяет код кандидата на должность мобильного разработчика. Эксперт создаёт тестовое задание, кандидат загружает решение (ZIP-архив или Git URL), система автоматически анализирует код по нескольким критериям и выставляет балл. Эксперт видит детальный отчёт и выносит финальный вердикт.

---

## Роли пользователей

| Роль | Платформа | Возможности |
|---|---|---|
| **Эксперт** | Веб (браузер) | Создаёт тестовые задания, настраивает чекеры и веса, просматривает все проверки, выносит вердикт ACCEPTED / REJECTED, смотрит статистику |
| **Кандидат** | Мобильное приложение (Flutter) | Регистрируется, загружает решение задания, отслеживает статус проверки, смотрит результаты |

---

## Архитектура системы

```
┌─────────────────────────────────────────────────────────────┐
│  Web Dashboard (React)          Mobile App (Flutter)        │
│  Эксперт                        Кандидат                   │
└────────────────┬────────────────────────────┬──────────────┘
                 │ HTTPS REST API              │ HTTPS REST API
                 ▼                            ▼
┌─────────────────────────────────────────────────────────────┐
│               Backend API  (Spring Boot + Kotlin)           │
│                    https://hrmanager.vrsalex.ru             │
└──────────┬──────────────────────────────┬───────────────────┘
           │                              │
    ┌──────▼──────┐              ┌────────▼────────┐
    │ PostgreSQL  │              │     Redis       │
    │  (данные)   │              │  (очередь+JWT)  │
    └─────────────┘              └────────┬────────┘
                                          │ очередь
                                 ┌────────▼────────┐
                                 │     Worker      │
                                 │ CheckOrchestrator│
                                 └────────┬────────┘
                          ┌───────────────▼──────────────────┐
                          │    Checker Containers (Docker)   │
                          │  StaticAnalysis · Architecture   │
                          │  Build · Tests · Documentation   │
                          │  GitPractices                    │
                          │  Каждый: изолирован, 512MB, 3мин │
                          └──────────────────────────────────┘
```

---

## Технологии

| Компонент | Стек |
|---|---|
| Backend | Spring Boot 3.4.5, Kotlin, Java 21 |
| База данных | PostgreSQL 16 |
| Очередь / кэш | Redis 7 |
| Миграции | Flyway |
| Аутентификация | JWT + Redis blacklist |
| Контейнеризация | Docker, Docker Compose |
| Checker-контейнеры | eclipse-temurin:21-jdk-alpine + Python 3 + git |
| API документация | Swagger UI / OpenAPI |
| Web | React |
| Mobile | Flutter |
| AI-анализ | Groq API (llama-3.1-8b-instant) |
| CI/CD | GitHub Actions |

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

---

## Структура репозитория

```
AutoCheckMobile/
├── Backend/
│   └── auth-check/           # Spring Boot бэкенд
│       ├── src/
│       ├── checker-scripts/  # Python-скрипты чекеров
│       ├── Dockerfile
│       ├── Dockerfile.worker
│       ├── checker.Dockerfile
│       ├── docker-compose.yml
│       └── .env.example
├── Web/
│   └── autoCheckMobileReact/ # React веб-дашборд
└── Mobile/                   # Flutter мобильное приложение
```

---

## Запуск бэкенда

### Требования
- Docker и Docker Compose

### 1. Клонировать репозиторий

```bash
git clone https://github.com/Vrs-Alex/AutoCheckMobile.git
cd AutoCheckMobile/Backend/auth-check
```

### 2. Создать файл с переменными окружения

```bash
cp .env.example .env
nano .env
```

Заполнить:

```env
DB_USERNAME=postgres
DB_PASSWORD=postgres
JWT_SECRET=минимум_32_символа_случайная_строка
AI_API_KEY=ваш_ключ_groq_или_openai
AI_BASE_URL=https://api.groq.com/openai
APP_URL=http://localhost:8080
DOCKER_UPLOADS_VOLUME=auth-check_uploads_data
CHECKER_IMAGE=autocheck-checker:latest
```

### 3. Запустить

```bash
sudo docker compose up --build -d
```

Первый запуск занимает 3–5 минут (скачиваются образы, компилируется проект).

### 4. Проверить

```bash
sudo docker compose ps
curl http://localhost:8080/api/docs
```

### Что запускается

| Контейнер | Роль | Порт |
|---|---|---|
| `backend` | REST API | 8080 |
| `worker` | Обработка очереди, запуск чекеров | — |
| `database` | PostgreSQL | внутренний |
| `redis` | Очередь задач + JWT blacklist | внутренний |
| `checker-runner` | Сборка образа для чекеров, сразу выходит | — |

### Ссылки после запуска

```
Swagger UI:  http://localhost:8080/api/swagger-ui.html
OpenAPI:     http://localhost:8080/api/docs
```

### Обновить после изменений в коде

```bash
git pull
sudo docker compose up --build -d
```

### Остановить

```bash
sudo docker compose down
```

---

## Запуск веб-дашборда (React)

### Требования
- Node.js 20+

### Локальная разработка

```bash
cd Web/autoCheckMobileReact
npm install
npm run dev
# Открыть http://localhost:5173
```

### Продакшен

```bash
cd Web/autoCheckMobileReact
npm install
npm run build
```

После сборки папка `dist/` содержит готовые статические файлы.

### Обновить после изменений в коде

```bash
git pull
cd Web/autoCheckMobileReact
npm install
npm run build
```

---

## Деплой на VPS (продакшен)

```bash
# 1. Установить Docker
curl -fsSL https://get.docker.com | sh

# 2. Клонировать
git clone https://github.com/Vrs-Alex/AutoCheckMobile.git
cd AutoCheckMobile/Backend/auth-check

# 3. Настроить окружение
cp .env.example .env
nano .env

# 4. Запустить бэкенд
sudo docker compose up --build -d

# 5. Собрать React
cd ../../Web/autoCheckMobileReact
npm install && npm run build
# скопировать dist/ в папку nginx
```

Система доступна по адресу: **https://hrmanager.vrsalex.ru**

---

## Формат API

Все ответы в едином формате:

```json
{ "data": { ... } }
{ "error": { "code": "NOT_FOUND", "message": "..." } }
{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": { "field": "msg" } } }
```

Авторизация: `Authorization: Bearer <token>` на все эндпоинты кроме `/auth/login` и `/auth/register`.

Полная документация: `/api/swagger-ui.html`

---

## CI/CD

При каждом пуше в любую ветку GitHub Actions автоматически:
1. Компилирует Kotlin
2. Запускает тесты
3. Проверяет сборку Docker образа

Статус виден во вкладке **Actions** репозитория.

---

## Переменные окружения

| Переменная | Описание |
|---|---|
| `DB_USERNAME` / `DB_PASSWORD` | Доступ к PostgreSQL |
| `JWT_SECRET` | Секрет подписи токенов (мин. 32 символа) |
| `AI_API_KEY` | Ключ LLM API (Groq / OpenAI) |
| `AI_BASE_URL` | Base URL провайдера (`https://api.groq.com/openai`) |
| `APP_URL` | Публичный URL сервиса |
| `DOCKER_UPLOADS_VOLUME` | Имя Docker volume для загрузок |
| `CHECKER_IMAGE` | Docker образ для чекеров |
