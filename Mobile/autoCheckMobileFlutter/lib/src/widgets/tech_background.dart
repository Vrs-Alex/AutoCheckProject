import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TechBackground extends StatelessWidget {
  const TechBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: CustomPaint(
        painter: _GridPainter(),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 1;

    const step = 56.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final cornerPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.45)
      ..strokeWidth = 1;

    canvas
      ..drawLine(const Offset(18, 18), const Offset(60, 18), cornerPaint)
      ..drawLine(const Offset(18, 18), const Offset(18, 60), cornerPaint)
      ..drawLine(Offset(size.width - 18, size.height - 18), Offset(size.width - 60, size.height - 18), cornerPaint)
      ..drawLine(Offset(size.width - 18, size.height - 18), Offset(size.width - 18, size.height - 60), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
