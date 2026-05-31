import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// Единая точка подключения SVG-иконок из assets/icons.
///
/// Иконки скачаны из публичной библиотеки Lucide и подключены через
/// flutter_svg, чтобы Flutter не падал из-за отсутствующих ассетов.
class TechIcon extends StatelessWidget {
  const TechIcon(
    this.type, {
    this.color,
    this.size = 22,
    super.key,
  });

  final TechIconType type;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
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
