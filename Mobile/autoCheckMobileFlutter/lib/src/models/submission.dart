// ============================================================================
// ENUMS: Статусы и типы данных
// ============================================================================

/// Статус отправки (Submission) кандидата.
/// Отражает текущее состояние процесса проверки кода.
enum SubmissionStatus {
  pending,   // Ожидает начала проверки
  running,   // Проверка выполняется
  passed,    // Успешно пройдена (балл >= порога)
  failed,    // Провалена (балл < порога)
  error,     // Ошибка системы при проверке
}

/// Вердикт эксперта или автоматической системы.
/// Используется для финального решения по кандидату.
enum Verdict {
  accepted,  // Принят
  rejected,  // Отклонен
  none,      // Вердикт еще не выставлен
}

/// Роль пользователя в системе.
enum UserRole {
  expert,    // Эксперт/Рекрутер (проверяет, создает задания)
  candidate, // Кандидат (загружает решения)
}

/// Статус тестового задания (Assignment).
enum AssignmentStatus {
  draft,     // Черновик (не видно кандидатам)
  published, // Опубликовано (доступно для сдачи)
}

/// Тип источника кода кандидата.
enum SourceType {
  zip,       // ZIP-архив
  git,       // Git-репозиторий
}

/// Название конкретного чекера (инструмента проверки).
enum CheckerName {
  staticAnalysis, // Статический анализ кода (linting)
  architecture,   // Проверка архитектуры проекта
  build,          // Сборка проекта (compile/build)
  tests,          // Запуск unit/integration тестов
  documentation,  // Проверка наличия и качества документации
  gitPractices,   // Анализ истории коммитов и git-практик
}

/// Статус выполнения отдельного чекера.
enum CheckerStatus {
  pending,   // В очереди
  running,   // Выполняется
  passed,    // Успешно
  failed,    // Не успешно
  error,     // Ошибка исполнения чекера
}

/// Тон события в таймлайне (визуальное отображение).
enum TimelineTone {
  done,    // Завершенное событие (зеленый/серый)
  active,  // Текущее/активное событие (акцентный цвет)
  muted,   // Второстепенное событие (тусклый цвет)
}

// ============================================================================
// MODELS: Классы данных
// ============================================================================

/// Конфигурация одного чекера внутри задания.
/// Определяет, включен ли чекер и какой вес он имеет в итоговом балле.
class CheckerConfig {
  const CheckerConfig({
    required this.checker,
    required this.enabled,
    required this.weight,
  });

  final CheckerName checker; // Тип чекера
  final bool enabled;        // Включен ли он
  final int weight;          // Вес в процентах или баллах

  /// Создает копию конфигурации с измененными полями.
  CheckerConfig copyWith({
    CheckerName? checker,
    bool? enabled,
    int? weight,
  }) {
    return CheckerConfig(
      checker: checker ?? this.checker,
      enabled: enabled ?? this.enabled,
      weight: weight ?? this.weight,
    );
  }
}

/// Тестовое задание (Assignment).
/// Содержит описание, требования и настройки проверки.
class Assignment {
  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.technologies,
    required this.checkerConfig,
    required this.instructionsMarkdown,
    required this.status,
    required this.createdAt,
  });

  final String id;                          // UUID задания
  final String title;                       // Название (напр. "Flutter Dev Test")
  final String description;                 // Краткое описание
  final List<String> technologies;          // Стек технологий (напр. ["Flutter", "Dart"])
  final List<CheckerConfig> checkerConfig;  // Настройки чекеров для этого задания
  final String instructionsMarkdown;        // Полные инструкции в формате MD
  final AssignmentStatus status;            // Черновик или опубликовано
  final DateTime createdAt;                 // Дата создания
}

/// Отправка (Submission) — решение кандидата.
/// Основная сущность, которая проходит проверку.
class Submission {
  // Специальный объект для отличия null от "не передано" в copyWith
  static const _notSet = Object();

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.candidateId,
    required this.candidateEmail,
    required this.candidateName,
    required this.createdAt,
    required this.score,
    required this.status,
    required this.verdict,
    this.fileName,
    this.gitUrl,
    this.completedAt,
    this.sourceType = SourceType.zip,
    this.verdictComment,
  });

  final String id;                // UUID отправки
  final String assignmentId;      // ID связанного задания
  final String assignmentTitle;   // Название задания (денормализация для удобства)
  final String candidateId;       // ID кандидата
  final String candidateName;     // Имя кандидата
  final String candidateEmail;    // Email кандидата
  final DateTime createdAt;       // Время загрузки решения
  final DateTime? completedAt;    // Время завершения проверки (null если еще идет)
  final SourceType sourceType;    // Как загружено: ZIP или Git
  final String? fileName;         // Имя файла (если ZIP)
  final String? gitUrl;           // URL репозитория (если Git)
  final int? score;               // Итоговый балл (0-100)
  final SubmissionStatus status;  // Статус процесса проверки
  final Verdict verdict;          // Финальный вердикт
  final String? verdictComment;   // Комментарий к вердикту

  /// Создает копию объекта с возможностью частичного обновления полей.
  /// Использует `_notSet` чтобы корректно обрабатывать установку поля в null.
  Submission copyWith({
    Object? completedAt = _notSet,
    Object? fileName = _notSet,
    Object? gitUrl = _notSet,
    Object? score = _notSet,
    Object? verdictComment = _notSet,
    SourceType? sourceType,
    SubmissionStatus? status,
    Verdict? verdict,
  }) {
    return Submission(
      id: id,
      assignmentId: assignmentId,
      assignmentTitle: assignmentTitle,
      candidateId: candidateId,
      candidateEmail: candidateEmail,
      candidateName: candidateName,
      createdAt: createdAt,
      // Логика: если передан _notSet, оставляем старое значение, иначе берем новое (даже если null)
      completedAt: identical(completedAt, _notSet) ? this.completedAt : completedAt as DateTime?,
      fileName: identical(fileName, _notSet) ? this.fileName : fileName as String?,
      gitUrl: identical(gitUrl, _notSet) ? this.gitUrl : gitUrl as String?,
      score: identical(score, _notSet) ? this.score : score as int?,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      verdict: verdict ?? this.verdict,
      verdictComment: identical(verdictComment, _notSet) ? this.verdictComment : verdictComment as String?,
    );
  }
}

/// Результат работы одного конкретного чекера.
class CheckResult {
  const CheckResult({
    required this.checker,
    required this.status,
    required this.score,
    required this.message,
    required this.log,
    required this.durationMs,
  });

  final String checker;      // Название чекера (напр. "static_analysis")
  final CheckerStatus status;// Статус выполнения
  final int score;           // Балл, выданный этим чекером
  final String message;      // Короткое сообщение (напр. "Build failed")
  final String log;          // Полный лог вывода консоли
  final int durationMs;      // Время выполнения в миллисекундах
}

/// Событие в таймлайне активности (например, история изменений статуса).
class TimelineEvent {
  const TimelineEvent({
    required this.label,
    required this.time,
    required this.tone,
  });

  final String label;      // Текст события (напр. "Загрузка завершена")
  final DateTime time;     // Время события
  final TimelineTone tone; // Визуальный стиль (активный, завершенный, тусклый)
}

/// Отзыв AI-ассистента по коду кандидата.
class AiReview {
  const AiReview({
    required this.summary,
    required this.good,
    required this.improvements,
  });

  final String summary;         // Краткое резюме
  final List<String> good;      // Список плюсов ("Чистая архитектура", "Хорошие тесты")
  final List<String> improvements; // Список зон роста ("Добавить линтер", "Упростить виджеты")
}

// ============================================================================
// STATISTICS MODELS: Данные для дашборда и статистики
// ============================================================================

/// Общая сводка статистики на дашборде.
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.averageScore,
    required this.passRate,
    required this.awaiting,
  });

  final int total;          // Всего отправок
  final int averageScore;   // Средний балл
  final double passRate;    // Процент успешных (0.0 - 1.0)
  final int awaiting;       // Ожидают проверки
}

/// Количество отправок за один день (для графика).
class DailyCount {
  const DailyCount({
    required this.date,
    required this.count,
  });

  final String date; // Дата в формате YYYY-MM-DD
  final int count;   // Количество
}

/// Лучший кандидат в топе.
class TopCandidate {
  const TopCandidate({
    required this.id,
    required this.fullName,
    required this.bestScore,
  });

  final String id;
  final String fullName;
  final double bestScore;
}

/// Полный набор данных для экрана статистики.
class StatisticsData {
  const StatisticsData({
    required this.stats,
    required this.dailyCounts,
    required this.topCandidates,
  });

  final DashboardStats stats;
  final List<DailyCount> dailyCounts;
  final List<TopCandidate> topCandidates;
}

// ============================================================================
// CONSTANTS & HELPERS
// ============================================================================

/// Конфигурация чекеров по умолчанию для новых заданий.
const defaultCheckerConfig = <CheckerConfig>[
  CheckerConfig(checker: CheckerName.staticAnalysis, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.architecture, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.build, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.tests, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.documentation, enabled: true, weight: 10),
  CheckerConfig(checker: CheckerName.gitPractices, enabled: true, weight: 10),
];

/// Возвращает человеко-читаемое название чекера на русском языке.
String checkerLabel(CheckerName checker) {
  return switch (checker) {
    CheckerName.staticAnalysis => 'Статический анализ',
    CheckerName.architecture => 'Архитектура',
    CheckerName.build => 'Сборка',
    CheckerName.tests => 'Unit-тесты',
    CheckerName.documentation => 'Документация',
    CheckerName.gitPractices => 'Git-практики',
  };
}

/// Возвращает техническое имя чекера (для API или логов).
String checkerRawName(CheckerName checker) {
  return switch (checker) {
    CheckerName.staticAnalysis => 'STATIC_ANALYSIS',
    CheckerName.architecture => 'ARCHITECTURE',
    CheckerName.build => 'BUILD',
    CheckerName.tests => 'TESTS',
    CheckerName.documentation => 'DOCUMENTATION',
    CheckerName.gitPractices => 'GIT_PRACTICES',
  };
}