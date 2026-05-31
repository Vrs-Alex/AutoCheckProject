# AutoCheck Flutter

Flutter-версия dashboard в стиле React-макета: строгий dark high-tech, sharp corners, тонкие границы, один акцент `#00ff66`, реальный backend, комментарии и логирование действий.

## Как запустить

Если папка уже открыта в Flutter/Android Studio:

```bash
flutter pub get
flutter run --dart-define=AUTOCHECK_API_URL=http://localhost:8080/api/v1
```

Для Android emulator вместо `localhost` нужен адрес хоста:

```bash
flutter run --dart-define=AUTOCHECK_API_URL=http://10.0.2.2:8080/api/v1
```

Если Flutter скажет, что нет platform files (`android`, `ios`, `macos`, `web`), выполните в этой папке:

```bash
flutter create . --platforms=android,ios,macos,web
flutter pub get
flutter run
```

Команда `flutter create .` не должна перезатереть `lib/`, `pubspec.yaml` и дизайн-код; она добавит только стандартные платформенные папки.

## Демо-логин

```text
expert@autocheck.local
secret123
```

Если база backend свежая, нажмите `Создать пользователя` на экране входа. Flutter вызовет реальный `POST /api/v1/auth/register`, сохранит JWT в памяти и откроет dashboard.

## Что есть

- Login/register screen через настоящий backend.
- Dashboard со статистикой и списком проверок из `/api/v1`.
- Submission details с score card, checker matrix, timeline, AI analysis.
- Создание задания через `/assignments`.
- Загрузка решения ZIP или Git URL через `/submissions`.
- Отдельный экран статистики с daily counts и рейтингом кандидатов из `/reports/stats`.
- Verdict modal.
- BackendRepository: JWT, ApiResponse unwrap, multipart upload, polling-compatible endpoints.
- DTO-слой `ApiSubmissionDto`, `ApiCheckResultDto`, `ApiAiReviewDto`, `ApiVerdictRequest` с именами полей из `openapi.yaml`.
- Локальные SVG-иконки в `assets/icons/` из публичного набора Lucide, подключены через `flutter_svg`.
- AppLogger с форматом логов:

```text
[LoginScreen]: INFO Login request started - {"email":"expert@autocheck.local"}
[SubmissionDetailsScreen]: DEBUG Verdict update completed - {"submissionId":"s1","verdict":"accepted"}
```

## Стиль

При добавлении новых экранов держать этот стиль:

```text
Продолжай в текущем стиле AutoCheck Premium High-Tech: глубокий фон #06070b, панели #0d0f17, острые углы, border 1px rgba(255,255,255,0.06), padding минимум 2rem внутри больших блоков, моноширинные uppercase label с letter-spacing, один главный акцент #00ff66 только микродозами. Не подключать тяжелые runtime icon packs: если нужна новая иконка, положи SVG из Lucide в assets/icons и добавь его в TechIcon. Не использовать glow-orbs, gradient blobs, большие border-radius и сине-фиолетовые SaaS-цвета.
```
