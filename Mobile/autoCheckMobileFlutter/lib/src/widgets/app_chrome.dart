import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tech_background.dart';
import 'tech_components.dart';
import 'tech_icon.dart';

/// Общая оболочка приложения: sidebar, topbar, адаптивные отступы и фон.
class AppChrome extends StatelessWidget {
  const AppChrome({
    required this.child,
    required this.onDashboard,
    this.onCreateAssignment,
    this.onStatistics,
    this.onUploadSubmission,
    this.selected = 'dashboard',
    super.key,
  });

  final Widget child;
  final String selected;
  final VoidCallback onDashboard;
  final VoidCallback? onCreateAssignment;
  final VoidCallback? onStatistics;
  final VoidCallback? onUploadSubmission;

  @override
  Widget build(BuildContext context) {
    return TechBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;
              return Row(
                children: [
                  if (wide)
                    _SideRail(
                      onCreateAssignment: onCreateAssignment,
                      onDashboard: onDashboard,
                      onStatistics: onStatistics,
                      onUploadSubmission: onUploadSubmission,
                      selected: selected,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(wide: wide),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 40 : 16,
                              vertical: wide ? 56 : 34,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: child,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.onCreateAssignment,
    required this.onDashboard,
    required this.onStatistics,
    required this.onUploadSubmission,
    required this.selected,
  });

  final String selected;
  final VoidCallback onDashboard;
  final VoidCallback? onCreateAssignment;
  final VoidCallback? onStatistics;
  final VoidCallback? onUploadSubmission;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundAlt,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
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
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.border),
                ),
                child: const TechIcon(
                  TechIconType.clipboard,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AutoCheck',
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TechLabel('Expert console'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          const TechLabel('[ 55.7558 N, 37.6173 E ]'),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(height: 7, width: 7, color: AppColors.accent),
              const SizedBox(width: 10),
              const Text('Backend API online', style: TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 20),
          _NavItem(
            active: selected == 'dashboard',
            icon: TechIconType.grid,
            label: 'Дашборд',
            onTap: onDashboard,
          ),
          _NavItem(
            active: selected == 'upload',
            icon: TechIconType.upload,
            label: 'Загрузка',
            onTap: onUploadSubmission ?? () => Navigator.of(context).pushNamed('/submissions/new'),
          ),
          _NavItem(
            active: selected == 'create',
            icon: TechIconType.plus,
            label: 'Создать задание',
            onTap: onCreateAssignment ?? () => Navigator.of(context).pushNamed('/assignments/new'),
          ),
          _NavItem(
            active: selected == 'statistics',
            icon: TechIconType.chart,
            label: 'Статистика',
            onTap: onStatistics ?? () => Navigator.of(context).pushNamed('/statistics'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final TechIconType icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.panel : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? AppColors.accent : Colors.transparent,
              width: 3,
            ),
            top: BorderSide(color: active ? AppColors.border : Colors.transparent),
            right: BorderSide(color: active ? AppColors.border : Colors.transparent),
            bottom: BorderSide(color: active ? AppColors.border : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            TechIcon(icon, color: active ? AppColors.text : AppColors.muted, size: 18),
            const SizedBox(width: 14),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: active ? AppColors.text : AppColors.muted,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 72 : 64,
      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16),
      decoration: const BoxDecoration(
        color: Color(0xE608080C),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            Container(
              height: 38,
              width: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
              ),
              child: const TechIcon(TechIconType.menu, color: AppColors.muted, size: 19),
            ),
            const SizedBox(width: 14),
            const TechIcon(TechIconType.clipboard, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            const Text(
              'AutoCheck',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else ...[
            Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.panel,
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  TechIcon(TechIconType.search, color: AppColors.dim, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: TechLabel('Search candidate / assignment / run'),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (wide)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Алексей Морозов',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TechLabel('expert@autocheck.local'),
              ],
            ),
          const SizedBox(width: 14),
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'A',
              style: TextStyle(
                color: AppColors.accent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const TechIcon(TechIconType.logout, color: AppColors.muted, size: 18),
          if (wide) ...[
            const SizedBox(width: 10),
            const TechLabel('Выход'),
          ],
        ],
      ),
    );
  }
}
