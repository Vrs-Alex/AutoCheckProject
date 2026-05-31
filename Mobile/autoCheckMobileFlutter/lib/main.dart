import 'package:flutter/material.dart';

import 'src/screens/create_assignment_screen.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/statistics_screen.dart';
import 'src/screens/upload_submission_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const AutoCheckApp());
}

/// Назначение: корневой виджет Flutter-клиента AutoCheck.
///
/// Ответственность/SRP: подключает тему, стартовый экран и маршруты основных
/// сценариев без сетевой и бизнес-логики.
///
/// Дата создания: 31-05-2026.
/// Автор: Команда.
///
/// Публичные методы: [build] создаёт MaterialApp и карту маршрутов.
class AutoCheckApp extends StatelessWidget {
  const AutoCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoCheck',
      theme: AppTheme.data,
      home: const LoginScreen(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/assignments/new': (_) => const CreateAssignmentScreen(),
        '/submissions/new': (_) => const UploadSubmissionScreen(),
        '/statistics': (_) => const StatisticsScreen(),
      },
    );
  }
}
