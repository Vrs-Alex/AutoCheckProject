import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Типы доступных иконок в системе.
/// Соответствуют файлам в папке assets/icons/.
enum TechIconType {
  activity,
  alert,
  bot,
  chart,
  check,
  chevronDown,
  chevronRight,
  clipboard,
  close,
  download,
  grid,
  lock,
  logout,
  mail,
  menu,
  plus,
  refresh,
  search,
  shield,
  thumbDown,
  thumbUp,
  upload,
  user,
}

/// Универсальный виджет для отображения SVG-иконок из набора Lucide
class TechIcon extends StatelessWidget {
  const TechIcon(
      this.type, {
        this.color,
        this.size = 22, // Стандартный размер иконки
        super.key,
      });

  final TechIconType type; // Тип иконки (ключ для маппинга пути к файлу)
  final Color? color;      // Опциональный цвет иконки
  final double size;       // Размер стороны квадрата иконки

  @override
  Widget build(BuildContext context) {
    // Определение финального цвета
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.white;

    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        _iconAssets[type]!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        fit: BoxFit.contain,
        semanticsLabel: type.name,
      ),
    );
  }
}

/// Маппинг типов иконок на пути к SVG-файлам в проекте.
const _iconAssets = <TechIconType, String>{
  TechIconType.activity: 'assets/icons/activity.svg',
  TechIconType.alert: 'assets/icons/alert.svg',
  TechIconType.bot: 'assets/icons/bot.svg',
  TechIconType.chart: 'assets/icons/chart.svg',
  TechIconType.check: 'assets/icons/check.svg',
  TechIconType.chevronDown: 'assets/icons/chevron-down.svg',
  TechIconType.chevronRight: 'assets/icons/chevron-right.svg',
  TechIconType.clipboard: 'assets/icons/clipboard.svg',
  TechIconType.close: 'assets/icons/close.svg',
  TechIconType.download: 'assets/icons/download.svg',
  TechIconType.grid: 'assets/icons/grid.svg',
  TechIconType.lock: 'assets/icons/lock.svg',
  TechIconType.logout: 'assets/icons/logout.svg',
  TechIconType.mail: 'assets/icons/mail.svg',
  TechIconType.menu: 'assets/icons/menu.svg',
  TechIconType.plus: 'assets/icons/plus.svg',
  TechIconType.refresh: 'assets/icons/refresh.svg',
  TechIconType.search: 'assets/icons/search.svg',
  TechIconType.shield: 'assets/icons/shield.svg',
  TechIconType.thumbDown: 'assets/icons/thumb-down.svg',
  TechIconType.thumbUp: 'assets/icons/thumb-up.svg',
  TechIconType.upload: 'assets/icons/upload.svg',
  TechIconType.user: 'assets/icons/user.svg',
};