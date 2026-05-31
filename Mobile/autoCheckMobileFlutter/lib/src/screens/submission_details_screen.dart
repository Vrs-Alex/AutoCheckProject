import 'dart:async';

import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../services/app_logger.dart';
import '../services/formatters.dart';
import '../services/backend_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/tech_components.dart';
import '../widgets/tech_icon.dart';

/// Карточка проверки: score, checker matrix, timeline, AI review и вердикт.
class SubmissionDetailsScreen extends StatefulWidget {
  const SubmissionDetailsScreen({
    required this.submissionId,
    super.key,
  });

  final String submissionId;

  @override
  State<SubmissionDetailsScreen> createState() => _SubmissionDetailsScreenState();
}

class _SubmissionDetailsScreenState extends State<SubmissionDetailsScreen> {
  final _repository = BackendRepository.instance;

  late Future<_DetailsData> _future;
  Timer? _pollTimer;
  bool _rerunLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _future = _load());
    });
  }

  Future<_DetailsData> _load() async {
    final submission = await _repository.submissionById(widget.submissionId);
    final results = await _repository.results(widget.submissionId);
    final review = await _loadAiReview();
    final timeline = await _repository.timeline(submission);
    if (submission.status != SubmissionStatus.pending && submission.status != SubmissionStatus.running) {
      _pollTimer?.cancel();
    }
    return _DetailsData(
      review: review,
      results: results,
      submission: submission,
      timeline: timeline,
    );
  }

  Future<AiReview> _loadAiReview() async {
    try {
      return await _repository.aiReview(widget.submissionId);
    } catch (error) {
      AppLogger.error('SubmissionDetailsScreen', 'AI review load failed', error);
      return const AiReview(
        summary: 'AI-анализ недоступен: backend не вернул рекомендации.',
        good: [],
        improvements: [],
      );
    }
  }

  Future<void> _rerun() async {
    setState(() => _rerunLoading = true);
    try {
      AppLogger.info('SubmissionDetailsScreen', 'Rerun requested', {'submissionId': widget.submissionId});
      await _repository.rerun(widget.submissionId);
      AppLogger.debug('SubmissionDetailsScreen', 'Rerun completed', {'submissionId': widget.submissionId});
      _startPolling();
      setState(() => _future = _load());
    } catch (error) {
      AppLogger.error('SubmissionDetailsScreen', 'Rerun failed', error);
    } finally {
      if (mounted) setState(() => _rerunLoading = false);
    }
  }

  Future<void> _updateVerdict(Verdict verdict) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => _VerdictDialog(verdict: verdict),
    );
    if (comment == null) return;

    try {
      AppLogger.info(
        'SubmissionDetailsScreen',
        'Verdict update started',
        {'submissionId': widget.submissionId, 'verdict': verdict.name},
      );
      await _repository.updateVerdict(widget.submissionId, verdict, comment);
      AppLogger.debug(
        'SubmissionDetailsScreen',
        'Verdict update completed',
        {'submissionId': widget.submissionId, 'verdict': verdict.name, 'comment': comment},
      );
      setState(() => _future = _load());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вердикт сохранен')),
      );
    } catch (error) {
      AppLogger.error('SubmissionDetailsScreen', 'Verdict update failed', error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      onDashboard: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      selected: 'details',
      child: FutureBuilder<_DetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TechPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TechLabel('Backend error'),
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

          if (!snapshot.hasData) {
            return const TechPanel(
              child: SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailsHeader(
                loading: _rerunLoading,
                onAccept: () => _updateVerdict(Verdict.accepted),
                onExport: () async {
                  AppLogger.info(
                    'SubmissionDetailsScreen',
                    'Report export requested',
                    {'submissionId': widget.submissionId},
                  );
                  final report = await _repository.report(widget.submissionId);
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (_) => _ReportDialog(report: report),
                  );
                },
                onReject: () => _updateVerdict(Verdict.rejected),
                onRerun: _rerun,
                submission: data.submission,
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final left = Column(
                    children: [
                      _ScoreCard(submission: data.submission),
                      const SizedBox(height: 28),
                      _TimelinePanel(events: data.timeline),
                    ],
                  );
                  final right = Column(
                    children: [
                      _ResultsPanel(results: data.results),
                      const SizedBox(height: 28),
                      _AiPanel(review: data.review),
                    ],
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        left,
                        const SizedBox(height: 28),
                        right,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 380, child: left),
                      const SizedBox(width: 32),
                      Expanded(child: right),
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

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.loading,
    required this.onAccept,
    required this.onExport,
    required this.onReject,
    required this.onRerun,
    required this.submission,
  });

  final Submission submission;
  final bool loading;
  final VoidCallback onRerun;
  final VoidCallback onExport;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TechLabel('Run card / submission node'),
            const SizedBox(height: 18),
            Text(
              submission.candidateName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 18),
            Text(
              '${submission.assignmentTitle} / ${formatDateTime(submission.createdAt)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TechButton(
              icon: TechIconType.refresh,
              label: 'Перезапустить',
              loading: loading,
              onPressed: onRerun,
              variant: TechButtonVariant.secondary,
            ),
            TechButton(
              icon: TechIconType.download,
              label: 'Скачать отчет',
              onPressed: onExport,
              variant: TechButtonVariant.secondary,
            ),
            TechButton(
              icon: TechIconType.thumbUp,
              label: 'Принять',
              onPressed: onAccept,
            ),
            TechButton(
              icon: TechIconType.thumbDown,
              label: 'Отклонить',
              onPressed: onReject,
              variant: TechButtonVariant.danger,
            ),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 26),
              buttons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 32),
            buttons,
          ],
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: TechLabel('Итоговый балл')),
              Container(
                height: 50,
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const TechIcon(
                  TechIconType.shield,
                  color: AppColors.accent,
                  size: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                submission.score?.toString() ?? '--',
                style: TechText.monoValue.copyWith(
                  color: scoreColor(submission.score),
                  fontSize: 58,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 9),
                child: Text('/ 100', style: TextStyle(color: AppColors.dim)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            submission.assignmentTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.candidateName,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              StatusBadge(status: submission.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TechLabel('Pipeline events'),
          const SizedBox(height: 10),
          Text('Хронология', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ...events.map((event) {
            final color = switch (event.tone) {
              TimelineTone.done => AppColors.accent,
              TimelineTone.active => AppColors.danger,
              TimelineTone.muted => AppColors.dim,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    height: 10,
                    width: 10,
                    color: color,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.label,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(event.time),
                          style: TechText.label,
                        ),
                      ],
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

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results});

  final List<CheckResult> results;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TechLabel('Checker matrix'),
          const SizedBox(height: 10),
          Text('Детализация проверок', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 26),
          ...results.map((result) => _ResultCard(result: result)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.result});

  final CheckResult result;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.panelDeep,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundAlt,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TechIcon(
                      _open ? TechIconType.chevronDown : TechIconType.chevronRight,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.checker,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          result.message,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(checkerStatus: result.status),
                  const SizedBox(width: 14),
                  Text(
                    result.score.toString(),
                    style: TextStyle(
                      color: scoreColor(result.score),
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                result.log,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({required this.review});

  final AiReview review;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundAlt,
                  border: Border.all(color: AppColors.border),
                ),
                child: const TechIcon(
                  TechIconType.bot,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TechLabel('AI inspection'),
                  Text('AI-анализ', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.panelDeep,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              review.summary,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 22),
          _AiList(title: 'Что хорошо', items: review.good),
          const SizedBox(height: 18),
          _AiList(title: 'Что улучшить', items: review.improvements),
        ],
      ),
    );
  }
}

class _AiList extends StatelessWidget {
  const _AiList({
    required this.items,
    required this.title,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(title),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.panelDeep,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(item, style: const TextStyle(color: AppColors.muted)),
          ),
        ),
      ],
    );
  }
}

class _VerdictDialog extends StatefulWidget {
  const _VerdictDialog({required this.verdict});

  final Verdict verdict;

  @override
  State<_VerdictDialog> createState() => _VerdictDialogState();
}

class _VerdictDialogState extends State<_VerdictDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.verdict == Verdict.accepted ? 'Принять кандидата' : 'Отклонить кандидата';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: TechPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: TechLabel(title)),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 38,
                      width: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const TechIcon(TechIconType.close, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.panelDeep,
                  hintText: 'Комментарий к вердикту',
                  hintStyle: TextStyle(color: AppColors.dim),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TechButton(
                    label: 'Отмена',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: TechButtonVariant.ghost,
                  ),
                  const SizedBox(width: 12),
                  TechButton(
                    label: 'Сохранить',
                    onPressed: () => Navigator.of(context).pop(_controller.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDialog extends StatelessWidget {
  const _ReportDialog({required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: TechPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('JSON-отчет', style: Theme.of(context).textTheme.titleLarge)),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 38,
                      width: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
                      child: const TechIcon(TechIconType.close, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  child: Text(
                    report,
                    style: const TextStyle(color: AppColors.muted, fontFamily: 'monospace', height: 1.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsData {
  const _DetailsData({
    required this.results,
    required this.review,
    required this.submission,
    required this.timeline,
  });

  final Submission submission;
  final List<CheckResult> results;
  final AiReview review;
  final List<TimelineEvent> timeline;
}
