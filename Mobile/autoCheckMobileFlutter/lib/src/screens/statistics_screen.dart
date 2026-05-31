import 'package:flutter/material.dart';

import '../models/submission.dart'; // Модели статистики
import '../services/app_logger.dart'; // Логирование
import '../services/backend_repository.dart'; // API запросы
import '../theme/app_theme.dart'; // Стили
import '../widgets/app_chrome.dart'; // Оболочка приложения
import '../widgets/tech_components.dart'; // Карточки метрик, панели
import '../widgets/tech_icon.dart'; // Иконки

/// Экран общей статистики и аналитики (Telemetry).
///
/// Отображает:
/// 1. KPI метрики (всего проверок, средний балл, pass rate).
/// 2. График динамики проверок за последние дни (бар-чарт).
/// 3. Рейтинг лучших кандидатов (Top List).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _repository = BackendRepository.instance;

  late Future<StatisticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Загружает агрегированные данные статистики с бэкенда.
  Future<StatisticsData> _load() async {
    AppLogger.info('StatisticsScreen', 'Statistics load started');
    final data = await _repository.statistics();
    AppLogger.debug('StatisticsScreen', 'Statistics load completed', {'total': data.stats.total});
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      selected: 'statistics', // Подсветка пункта меню
      onDashboard: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onStatistics: () {},
      child: FutureBuilder<StatisticsData>(
        future: _future,
        builder: (context, snapshot) {
          // Обработка ошибки загрузки
          if (snapshot.hasError) {
            return TechPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TechLabel('Statistics error'),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: Color(0xFFFF7A3D), height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  TechButton(
                    icon: TechIconType.refresh,
                    label: 'Повторить',
                    onPressed: () => setState(() => _future = _load()),
                    variant: TechButtonVariant.secondary,
                  ),
                ],
              ),
            );
          }

          // Состояние загрузки
          if (!snapshot.hasData) {
            return const TechPanel(
              child: SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 1.5),
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TechLabel('Sprint-4 / telemetry'),
              const SizedBox(height: 18),
              Text('Статистика', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 20),
              const Text(
                'Метрики AutoCheck и рейтинг кандидатов из реального backend.',
                style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.55),
              ),
              const SizedBox(height: 48),

              // Сетка с основными KPI
              _MetricGrid(stats: data.stats),
              const SizedBox(height: 32),

              // Адаптивная область: График + Рейтинг
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;

                  final chart = _DailyChart(items: data.dailyCounts);
                  final ranking = _TopCandidates(items: data.topCandidates);

                  if (!wide) {
                    // Мобильная верстка: вертикальный стек
                    return Column(
                      children: [
                        chart,
                        const SizedBox(height: 28),
                        ranking,
                      ],
                    );
                  }

                  // Десктопная верстка: ряд (График шире, рейтинг уже)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chart),
                      const SizedBox(width: 28),
                      Expanded(flex: 2, child: ranking),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Внутренние виджеты статистики
// ============================================================================

/// Сетка карточек с ключевыми метриками (KPI).
/// Адаптирует количество колонок под ширину экрана (1, 2 или 3).
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
          icon: TechIconType.chart,
          label: 'Всего проверок',
          value: stats.total.toString(),
          delta: 'backend total'
      ),
      MetricCard(
          icon: TechIconType.activity,
          label: 'Средний балл',
          value: stats.averageScore.toString(),
          delta: 'done only'
      ),
      MetricCard(
          icon: TechIconType.shield,
          label: 'Процент прохождения',
          value: '${stats.passRate.toStringAsFixed(1)}%',
          delta: 'accepted / total'
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Определение количества колонок
        final columns = constraints.maxWidth >= 920
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        // Расчет ширины карточки с учетом отступов
        final cardWidth = (constraints.maxWidth - (columns - 1) * 20) / columns;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
        );
      },
    );
  }
}

/// Кастомный столбчатый график (Bar Chart) динамики проверок.
/// Реализован через Flexbox (Row/Column) без внешних библиотек.
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.items});

  final List<DailyCount> items;

  @override
  Widget build(BuildContext context) {
    // Берем только последние 14 дней для наглядности
    final visible = items.take(14).toList();

    // Находим максимальное значение для масштабирования высоты столбцов
    final maxCount = visible.fold<int>(1, (max, item) => item.count > max ? item.count : max);

    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TechLabel('Runtime chart'),
          const SizedBox(height: 10),
          Text('Динамика проверок', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 28),
          SizedBox(
            height: 260, // Фиксированная высота области графика
            child: visible.isEmpty
                ? const Center(child: Text('Пока нет данных', style: TextStyle(color: AppColors.muted)))
                : Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Выравнивание по низу
              children: visible.map((item) {
                // Расчет высоты столбца в процентах от максимума
                // Минимальная высота 28px, максимальная ~218px
                final height = 28 + (item.count / maxCount) * 190;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Значение над столбцом
                        Text(item.count.toString(), style: TechText.label.copyWith(color: AppColors.text)),
                        const SizedBox(height: 8),

                        // Сам столбец
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.18),
                            border: Border.all(color: AppColors.accent.withOpacity(0.55)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Дата под столбцом (обрезаем год, оставляем MM-DD)
                        Text(
                            item.date.length >= 5 ? item.date.substring(item.date.length - 5) : item.date,
                            style: TechText.label
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Список топ-кандидатов с лучшим результатом.
class _TopCandidates extends StatelessWidget {
  const _TopCandidates({required this.items});

  final List<TopCandidate> items;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TechLabel('Candidate ranking'),
          const SizedBox(height: 10),
          Text('Топ кандидатов', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),

          if (items.isEmpty)
            const Text('Пока нет кандидатов', style: TextStyle(color: AppColors.muted))
          else
            ...items.take(10).map((candidate) {
              // Индекс для отображения места (01, 02, 03...)
              final index = items.indexOf(candidate) + 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.panelDeep,
                    border: Border.all(color: AppColors.border)
                ),
                child: Row(
                  children: [
                    // Номер места
                    Text(
                        index.toString().padLeft(2, '0'),
                        style: TechText.label.copyWith(color: AppColors.accent)
                    ),
                    const SizedBox(width: 14),

                    // Имя кандидата
                    Expanded(
                      child: Text(
                        candidate.fullName,
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
                      ),
                    ),

                    // Лучший балл (цвет зависит от величины)
                    Text(
                      candidate.bestScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: scoreColor(candidate.bestScore.round()),
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}