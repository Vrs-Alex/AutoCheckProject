import 'package:flutter/material.dart';

import '../models/submission.dart'; // Модели данных
import '../services/app_logger.dart'; // Сервис логирования
import '../services/formatters.dart'; // Утилиты форматирования (даты, чисел)
import '../services/backend_repository.dart'; // Репозиторий для API запросов
import '../theme/app_theme.dart'; // Цвета и стили
import '../widgets/app_chrome.dart'; // Общая оболочка приложения
import '../widgets/tech_components.dart'; // Кнопки, панели, метрики
import '../widgets/tech_icon.dart'; // Иконки
import 'create_assignment_screen.dart';
import 'statistics_screen.dart';
import 'submission_details_screen.dart';
import 'upload_submission_screen.dart';

/// Главный экран эксперта (Dashboard).
///
/// Отображает:
/// 1. KPI метрики (всего проверок, средний балл, процент прохождения).
/// 2. Список последних отправок (Submissions) с возможностью поиска.
/// 3. Быстрые действия: создание задания, загрузка решения, статистика.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = BackendRepository.instance;
  final _searchController = TextEditingController();

  // Future для асинхронной загрузки данных дашборда
  late Future<_DashboardData> _future;

  // Строка поискового запроса
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Запускаем загрузку данных при инициализации экрана
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Загружает статистику и список отправок с бэкенда.
  Future<_DashboardData> _load() async {
    final stats = await _repository.stats();
    final submissions = await _repository.submissions();
    return _DashboardData(stats: stats, submissions: submissions);
  }

  /// Открывает экран деталей конкретной отправки.
  void _openSubmission(Submission submission) {
    AppLogger.info('DashboardScreen', 'Submission row opened', {'submissionId': submission.id});
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubmissionDetailsScreen(submissionId: submission.id),
      ),
    );
  }

  /// Открывает экран создания нового задания.
  /// После возврата обновляет данные дашборда, если задание было успешно создано.
  Future<void> _openCreateAssignment() async {
    AppLogger.info('DashboardScreen', 'Create assignment screen opened');
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateAssignmentScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load()); // Перезагрузка данных
    }
  }

  /// Открывает экран загрузки решения кандидатом.
  Future<void> _openUploadSubmission() async {
    AppLogger.info('DashboardScreen', 'Upload submission screen opened');
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UploadSubmissionScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load()); // Перезагрузка данных
    }
  }

  /// Открывает экран общей статистики.
  Future<void> _openStatistics() async {
    AppLogger.info('DashboardScreen', 'Statistics screen opened');
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => StatisticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      onDashboard: () {},
      // Текущий экран уже дашборд
      onCreateAssignment: _openCreateAssignment,
      onStatistics: _openStatistics,
      onUploadSubmission: _openUploadSubmission,
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          // Состояние загрузки или ошибки
          if (!snapshot.hasData) {
            return _LoadingPanel(label: 'Загружаем dashboard');
          }

          final data = snapshot.data!;

          // Фильтрация списка отправок по поисковому запросу
          final submissions = data.submissions.where((item) {
            final query = _search.toLowerCase();
            if (query.isEmpty) return true;
            return item.candidateName.toLowerCase().contains(query) || item.candidateEmail.toLowerCase().contains(query) || item.assignmentTitle.toLowerCase().contains(query);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхний блок с приветствием и кнопками действий
              _HeroActions(
                onCreate: _openCreateAssignment,
                onUpload: _openUploadSubmission,
              ),
              SizedBox(height: 64),

              // Сетка с KPI метриками
              _MetricGrid(stats: data.stats),
              SizedBox(height: 64),

              // Панель со списком отправок (Queue Monitor)
              TechPanel(
                padding: EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechLabel('Queue monitor'),
                    SizedBox(height: 10),
                    Text(
                      'Все проверки',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 26),

                    // Поле поиска
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    SizedBox(height: 24),

                    // Список элементов (ограничен первыми 14 для производительности UI)
                    ...submissions.take(14).map(
                          (submission) => _SubmissionRow(
                            submission: submission,
                            onTap: () => _openSubmission(submission),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Внутренние виджеты дашборда
// ============================================================================

/// Верхний блок дашборда: заголовок, описание и кнопки действий.
/// Адаптируется под ширину экрана (колонка на мобильных, строка на десктопе).
class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.onCreate,
    required this.onUpload,
  });

  final VoidCallback onCreate;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        // Блок кнопок
        final actions = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TechButton(
              icon: TechIconType.plus,
              label: 'Создать задание',
              onPressed: onCreate,
            ),
            TechButton(
              icon: TechIconType.upload,
              label: 'Загрузить решение',
              onPressed: onUpload,
              variant: TechButtonVariant.secondary,
            ),
          ],
        );

        // Текстовый блок
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TechLabel('AutoCheck dashboard / expert node'),
            SizedBox(height: 18),
            Text(
              'Панель управления',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            SizedBox(height: 20),
            Text(
              'Контролируйте проверки, фильтруйте кандидатов и открывайте карточки результатов.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ],
        );

        // Адаптивная раскладка
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              SizedBox(height: 26),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            SizedBox(width: 32),
            actions,
          ],
        );
      },
    );
  }
}

/// Сетка карточек с метриками (KPI).
/// Адаптирует количество колонок под ширину экрана (1, 2 или 4 колонки).
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Определение количества колонок в зависимости от ширины
        final columns = width >= 980
            ? 4
            : width >= 620
                ? 2
                : 1;

        // Расчет ширины одной карточки с учетом отступов
        final cardWidth = (width - (columns - 1) * 20) / columns;

        final cards = [
          MetricCard(
            delta: '+12% за неделю',
            icon: TechIconType.clipboard,
            label: 'Всего проверок',
            value: stats.total.toString(),
          ),
          MetricCard(
            delta: 'По завершенным',
            icon: TechIconType.activity,
            label: 'Средний балл',
            value: stats.averageScore.toString(),
          ),
          MetricCard(
            delta: 'Passed / total',
            icon: TechIconType.chart,
            label: 'Процент прохождения',
            value: '${stats.passRate.toStringAsFixed(1)}%',
          ),
          MetricCard(
            delta: 'Pending + running',
            icon: TechIconType.upload,
            label: 'Ожидают',
            value: stats.awaiting.toString(),
          ),
        ];

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Поле поиска с иконкой лупы.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.panelDeep,
        hintText: 'Живой поиск по ФИО, email или заданию',
        hintStyle: TextStyle(color: AppColors.dim),
        prefixIcon: Padding(
          padding: EdgeInsets.all(14),
          child: TechIcon(TechIconType.search, color: AppColors.dim, size: 18),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 48),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero, // Sharp corners
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

/// Строка списка отправок (Submission Item).
/// Отображает аватар, имя кандидата, название задания, статус и балл.
/// Адаптируется под узкие экраны (вертикальная раскладка).
class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({
    required this.onTap,
    required this.submission,
  });

  final Submission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.panelDeep,
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            // Левая часть: Аватар + Инфо о кандидате
            final left = Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TechIcon(
                    TechIconType.user,
                    color: scoreColor(submission.score), // Цвет иконки зависит от балла
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.candidateName,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${submission.assignmentTitle} / ${submission.candidateEmail}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );

            // Правая часть: Статус + Балл + Стрелка
            final right = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(status: submission.status),
                SizedBox(width: 16),
                Text(
                  submission.score?.toString() ?? '--',
                  style: TextStyle(
                    color: scoreColor(submission.score),
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 12),
                TechIcon(TechIconType.chevronRight, color: AppColors.muted, size: 18),
              ],
            );

            // Адаптивная раскладка строки
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  left,
                  SizedBox(height: 16),
                  right,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: left),
                SizedBox(width: 16),
                // Дата создания (видна только на широких экранах)
                Text(
                  formatDateTime(submission.createdAt),
                  style: TechText.label,
                ),
                SizedBox(width: 24),
                right,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Панель загрузки (Loader).
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: SizedBox(
        height: 220,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 1.5,
                ),
              ),
              SizedBox(width: 14),
              Text(label, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Вспомогательный класс для хранения данных дашборда.
class _DashboardData {
  const _DashboardData({
    required this.stats,
    required this.submissions,
  });

  final DashboardStats stats;
  final List<Submission> submissions;
}
