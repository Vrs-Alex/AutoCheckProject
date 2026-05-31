import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../services/app_logger.dart';
import '../services/formatters.dart';
import '../services/backend_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/tech_components.dart';
import '../widgets/tech_icon.dart';
import 'create_assignment_screen.dart';
import 'statistics_screen.dart';
import 'submission_details_screen.dart';
import 'upload_submission_screen.dart';

/// Главный экран эксперта: KPI, поиск и очередь проверок из backend.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = BackendRepository.instance;
  final _searchController = TextEditingController();

  late Future<_DashboardData> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_DashboardData> _load() async {
    final stats = await _repository.stats();
    final submissions = await _repository.submissions();
    return _DashboardData(stats: stats, submissions: submissions);
  }

  void _openSubmission(Submission submission) {
    AppLogger.info('DashboardScreen', 'Submission row opened', {'submissionId': submission.id});
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubmissionDetailsScreen(submissionId: submission.id),
      ),
    );
  }

  Future<void> _openCreateAssignment() async {
    AppLogger.info('DashboardScreen', 'Create assignment screen opened');
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openUploadSubmission() async {
    AppLogger.info('DashboardScreen', 'Upload submission screen opened');
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UploadSubmissionScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openStatistics() async {
    AppLogger.info('DashboardScreen', 'Statistics screen opened');
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      onDashboard: () {},
      onCreateAssignment: _openCreateAssignment,
      onStatistics: _openStatistics,
      onUploadSubmission: _openUploadSubmission,
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _LoadingPanel(label: 'Загружаем dashboard');
          }

          final data = snapshot.data!;
          final submissions = data.submissions.where((item) {
            final query = _search.toLowerCase();
            if (query.isEmpty) return true;
            return item.candidateName.toLowerCase().contains(query) ||
                item.candidateEmail.toLowerCase().contains(query) ||
                item.assignmentTitle.toLowerCase().contains(query);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroActions(
                onCreate: _openCreateAssignment,
                onUpload: _openUploadSubmission,
              ),
              const SizedBox(height: 64),
              _MetricGrid(stats: data.stats),
              const SizedBox(height: 64),
              TechPanel(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TechLabel('Queue monitor'),
                    const SizedBox(height: 10),
                    Text(
                      'Все проверки',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 26),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 24),
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

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TechLabel('AutoCheck dashboard / expert node'),
            const SizedBox(height: 18),
            Text(
              'Панель управления',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20),
            const Text(
              'Контролируйте проверки, фильтруйте кандидатов и открывайте карточки результатов.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 26),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 32),
            actions,
          ],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? 4
            : width >= 620
                ? 2
                : 1;
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
      style: const TextStyle(color: AppColors.text),
      decoration: const InputDecoration(
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
          borderRadius: BorderRadius.zero,
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
                    color: scoreColor(submission.score),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.candidateName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${submission.assignmentTitle} / ${submission.candidateEmail}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final right = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(status: submission.status),
                const SizedBox(width: 16),
                Text(
                  submission.score?.toString() ?? '--',
                  style: TextStyle(
                    color: scoreColor(submission.score),
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                const TechIcon(TechIconType.chevronRight, color: AppColors.muted, size: 18),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  left,
                  const SizedBox(height: 16),
                  right,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Text(
                  formatDateTime(submission.createdAt),
                  style: TechText.label,
                ),
                const SizedBox(width: 24),
                right,
              ],
            );
          },
        ),
      ),
    );
  }
}

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
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 1.5,
                ),
              ),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.stats,
    required this.submissions,
  });

  final DashboardStats stats;
  final List<Submission> submissions;
}
