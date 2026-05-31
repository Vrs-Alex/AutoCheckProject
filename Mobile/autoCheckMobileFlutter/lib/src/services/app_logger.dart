import 'dart:convert';
import 'package:flutter/foundation.dart';

/// AppLogger: Единая точка клиентского логирования Flutter-приложения.
///
/// Назначение:
/// Стандартизирует вывод логов в консоль разработчика, обеспечивая соответствие
/// требованиям конкурсной документации по форматам DEBUG/INFO/ERROR.
///
/// Формат вывода:
/// [ComponentName]: LEVEL EventName - Details
///
/// Примеры:
/// [DashboardScreen]: INFO ScreenOpened - User: admin
/// [ApiRepository]: ERROR FetchFailed - TimeoutException
class AppLogger {
  const AppLogger._(); // Приватный конструктор предотвращает создание экземпляров

  /// Логирование диагностической информации (низкий приоритет).
  /// Используется для отслеживания успешных API-запросов, внутренних состояний.
  static void debug(String component, String event, [Object? details]) {
    _write('DEBUG', component, event, details);
  }

  /// Логирование важных событий приложения (средний приоритет).
  /// Используется для навигации между экранами, действий пользователя.
  static void info(String component, String event, [Object? details]) {
    _write('INFO', component, event, details);
  }

  /// Логирование ошибок (высокий приоритет).
  /// Используется для исключений, ошибок валидации, сбоев сети.
  static void error(String component, String event, [Object? details]) {
    _write('ERROR', component, event, details);
  }

  /// Внутренний метод записи лога в консоль.
  static void _write(
      String level,
      String component,
      String event,
      Object? details,
      ) {
    final suffix = _normalize(details);
    // Используем debugPrint вместо print для корректной работы с длинными строками во Flutter
    debugPrint('[$component]: $level $event - $suffix');
  }

  /// Нормализация деталей лога для безопасного вывода.
  /// Преобразует Map/List в JSON-строку, остальные объекты — в toString().
  static String _normalize(Object? details) {
    if (details == null) return 'No details';

    // Если это коллекция, пытаемся сериализовать в JSON для читаемости
    if (details is Map || details is List) {
      try {
        return jsonEncode(details);
      } catch (_) {
        // Если сериализация не удалась (циклические ссылки и т.д.), используем toString
        return details.toString();
      }
    }

    return details.toString();
  }
}