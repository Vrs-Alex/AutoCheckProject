import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Назначение: единая точка клиентского логирования Flutter-приложения.
///
/// Ответственность/SRP: форматирует события экранов, репозитория и пользовательских
/// действий в виде `[Component]: LEVEL Event - Details`, чтобы логи совпадали с
/// конкурсным требованием DEBUG/INFO/ERROR.
///
/// Дата создания: 31-05-2026.
/// Автор: Команда.
///
/// Публичные методы:
/// - [debug] — пишет диагностические события и успешные API-ответы.
/// - [info] — пишет жизненный цикл экранов и критичные действия пользователя.
/// - [error] — пишет ошибки API, валидации и выполнения сценариев.
class AppLogger {
  const AppLogger._();

  static void debug(String component, String event, [Object? details]) {
    _write('DEBUG', component, event, details);
  }

  static void info(String component, String event, [Object? details]) {
    _write('INFO', component, event, details);
  }

  static void error(String component, String event, [Object? details]) {
    _write('ERROR', component, event, details);
  }

  static void _write(
    String level,
    String component,
    String event,
    Object? details,
  ) {
    final suffix = _normalize(details);
    debugPrint('[$component]: $level $event - $suffix');
  }

  static String _normalize(Object? details) {
    if (details == null) return 'No details';
    if (details is Map || details is List) {
      try {
        return jsonEncode(details);
      } catch (_) {
        return details.toString();
      }
    }
    return details.toString();
  }
}
