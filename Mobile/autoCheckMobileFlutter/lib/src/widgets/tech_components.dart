import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../theme/app_theme.dart';
import 'tech_icon.dart';

class TechLabel extends StatelessWidget {
  const TechLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TechText.label,
    );
  }
}

/// Базовая sharp-панель с тонкой рамкой и декоративными техническими углами.
class TechPanel extends StatelessWidget {
  const TechPanel({
    required this.child,
    this.padding = const EdgeInsets.all(32),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _PanelCornersPainter(),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.panel.withOpacity(0.88),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 80,
              offset: const Offset(0, 28),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PanelCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final accent = Paint()
      ..color = AppColors.accent.withOpacity(0.78)
      ..strokeWidth = 1;
    final muted = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1;

    canvas
      ..drawLine(Offset.zero, const Offset(18, 0), accent)
      ..drawLine(Offset.zero, const Offset(0, 18), accent)
      ..drawLine(Offset(size.width, size.height), Offset(size.width - 18, size.height), muted)
      ..drawLine(Offset(size.width, size.height), Offset(size.width, size.height - 18), muted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum TechButtonVariant {
  primary,
  secondary,
  danger,
  ghost,
}

/// Единая кнопка интерфейса: sharp geometry, mono label, loading state.
class TechButton extends StatelessWidget {
  const TechButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = TechButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TechIconType? icon;
  final bool loading;
  final TechButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = switch (variant) {
      TechButtonVariant.primary => (
          background: AppColors.accent,
          border: AppColors.accent,
          foreground: AppColors.background,
        ),
      TechButtonVariant.secondary => (
          background: AppColors.panel,
          border: Colors.white.withOpacity(0.1),
          foreground: AppColors.text,
        ),
      TechButtonVariant.danger => (
          background: Colors.transparent,
          border: AppColors.danger.withOpacity(0.65),
          foreground: const Color(0xFFFF7A3D),
        ),
      TechButtonVariant.ghost => (
          background: Colors.transparent,
          border: Colors.transparent,
          foreground: AppColors.muted,
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: colors.foreground,
                    strokeWidth: 1.5,
                  ),
                )
              else if (icon != null)
                TechIcon(icon!, color: colors.foreground, size: 18),
              if (loading || icon != null) const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: colors.foreground,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    this.checkerStatus,
    this.status,
    this.verdict,
    super.key,
  });

  final SubmissionStatus? status;
  final CheckerStatus? checkerStatus;
  final Verdict? verdict;

  @override
  Widget build(BuildContext context) {
    final text = verdict != null
        ? _verdictLabel(verdict!)
        : checkerStatus != null
            ? _checkerLabel(checkerStatus!)
            : _submissionLabel(status ?? SubmissionStatus.pending);
    final color = verdict != null
        ? _verdictColor(verdict!)
        : checkerStatus != null
            ? _checkerColor(checkerStatus!)
            : _submissionColor(status ?? SubmissionStatus.pending);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.38)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    super.key,
  });

  final String label;
  final String value;
  final String delta;
  final TechIconType icon;

  @override
  Widget build(BuildContext context) {
    return TechPanel(
      padding: const EdgeInsets.all(32),
      child: SizedBox(
        height: 172,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TechLabel(label)),
                Container(
                  height: 42,
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TechIcon(icon, color: AppColors.accent, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(value, style: TechText.monoValue),
            const SizedBox(height: 14),
            Text(
              delta.toUpperCase(),
              style: TechText.label.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

Color scoreColor(int? score) {
  if (score == null) return AppColors.muted;
  if (score >= 80) return AppColors.accent;
  if (score >= 50) return AppColors.text;
  return const Color(0xFFFF7A3D);
}

String _submissionLabel(SubmissionStatus status) {
  return switch (status) {
    SubmissionStatus.pending => 'Ожидает',
    SubmissionStatus.running => 'Проверяется',
    SubmissionStatus.passed => 'Успешно',
    SubmissionStatus.failed => 'Провалено',
    SubmissionStatus.error => 'Ошибка',
  };
}

String _checkerLabel(CheckerStatus status) {
  return switch (status) {
    CheckerStatus.pending => 'Ожидает',
    CheckerStatus.running => 'Проверяется',
    CheckerStatus.passed => 'Успешно',
    CheckerStatus.failed => 'Провалено',
    CheckerStatus.error => 'Ошибка',
  };
}

String _verdictLabel(Verdict verdict) {
  return switch (verdict) {
    Verdict.accepted => 'Принят',
    Verdict.rejected => 'Отклонен',
    Verdict.none => 'Без вердикта',
  };
}

Color _submissionColor(SubmissionStatus status) {
  return switch (status) {
    SubmissionStatus.pending => AppColors.muted,
    SubmissionStatus.running => AppColors.accent,
    SubmissionStatus.passed => AppColors.accent,
    SubmissionStatus.failed => const Color(0xFFFF7A3D),
    SubmissionStatus.error => const Color(0xFFFF7A3D),
  };
}

Color _checkerColor(CheckerStatus status) {
  return switch (status) {
    CheckerStatus.pending => AppColors.muted,
    CheckerStatus.running => AppColors.accent,
    CheckerStatus.passed => AppColors.accent,
    CheckerStatus.failed => const Color(0xFFFF7A3D),
    CheckerStatus.error => const Color(0xFFFF7A3D),
  };
}

Color _verdictColor(Verdict verdict) {
  return switch (verdict) {
    Verdict.accepted => AppColors.accent,
    Verdict.rejected => const Color(0xFFFF7A3D),
    Verdict.none => AppColors.muted,
  };
}
