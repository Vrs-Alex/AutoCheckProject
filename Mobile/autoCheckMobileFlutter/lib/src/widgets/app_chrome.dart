import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tech_background.dart';
import 'tech_components.dart';
import 'tech_icon.dart';

/// Общая оболочка приложения: sidebar, topbar, адаптивные отступы и фон.
class AppChrome extends StatelessWidget {
  AppChrome({
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
              // Определяем, является ли экран широким (десктоп/планшет)
              final wide = constraints.maxWidth >= 940;
              return Row(
                children: [
                  // Боковая панель отображается только на широких экранах
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
                        // Верхняя панель
                        _TopBar(wide: wide),
                        Expanded(
                          child: SingleChildScrollView(
                            // Адаптивные отступы в зависимости от ширины экрана
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 40 : 16,
                              vertical: wide ? 56 : 34,
                            ),
                            child: ConstrainedBox(
                              // Ограничение максимальной ширины контента для удобства чтения
                              constraints: BoxConstraints(maxWidth: 1180),
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

// Боковая навигационная панель (сайдбар)
class _SideRail extends StatelessWidget {
  _SideRail({
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Логотип и название приложения
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
                child: TechIcon(
                  TechIconType.clipboard,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Column(
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
          SizedBox(height: 42),
          Divider(color: AppColors.border),
          SizedBox(height: 14),

          // Декоративный блок статуса системы
          TechLabel('[ 55.7558 N, 37.6173 E ]'),
          SizedBox(height: 10),
          Row(
            children: [
              Container(height: 7, width: 7, color: AppColors.accent),
              SizedBox(width: 10),
              Text('Backend API online', style: TextStyle(color: AppColors.muted)),
            ],
          ),
          SizedBox(height: 24),
          Divider(color: AppColors.border),
          SizedBox(height: 20),

          // Пункты меню навигации
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
            // Если колбэк не передан, используется стандартная навигация
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

// Элемент пункта меню
class _NavItem extends StatelessWidget {
  _NavItem({
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
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            SizedBox(width: 14),
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

// Верхняя панель (TopBar)
class _TopBar extends StatelessWidget {
  _TopBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 72 : 64,
      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16),
      decoration: BoxDecoration(
        color: Color(0xE608080C),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Контент для мобильных устройств (кнопка меню и логотип)
          if (!wide) ...[
            Container(
              height: 38,
              width: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
              ),
              child: TechIcon(TechIconType.menu, color: AppColors.muted, size: 19),
            ),
            SizedBox(width: 14),
            TechIcon(TechIconType.clipboard, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text(
              'AutoCheck',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ]
          // Контент для десктопа (поиск)
          else ...[
            Container(
              width: 420,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.panel,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
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
          Spacer(),

          // Профиль пользователя (справа)
          if (wide)
            Column(
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
          SizedBox(width: 14),

          // Аватар пользователя
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'A',
              style: TextStyle(
                color: AppColors.accent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 14),

          // Кнопка выхода
          TechIcon(TechIconType.logout, color: AppColors.muted, size: 18),
          if (wide) ...[
            SizedBox(width: 10),
            TechLabel('Выход'),
          ],
        ],
      ),
    );
  }
}
