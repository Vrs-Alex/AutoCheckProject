import 'package:flutter/material.dart';
import '../models/submission.dart'; // Модели: Assignment, CheckerConfig, enums
import '../services/app_logger.dart'; // Сервис логирования
import '../services/backend_repository.dart'; // Репозиторий для API запросов
import '../theme/app_theme.dart'; // Цвета и стили
import '../widgets/app_chrome.dart'; // Общая оболочка приложения
import '../widgets/tech_components.dart'; // Кнопки, панели, лейблы
import '../widgets/tech_icon.dart'; // Иконки

/// Экран создания нового тестового задания (Assignment).
///
/// Позволяет эксперту настроить параметры задания:
/// 1. Метаданные (название, описание, технологии, инструкция).
/// 2. Конфигурацию автоматических чекеров (включение/выключение, веса).
/// 3. Сохранить как черновик или опубликовать сразу.
class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _repository = BackendRepository.instance;

  // Контроллеры текстовых полей с предустановленными значениями-примерами
  final _title = TextEditingController(text: 'Mobile Clean Architecture Challenge');
  final _description = TextEditingController(text: 'Проверка мобильного проекта на архитектуру, сборку, тесты и документацию.');
  final _technologies = TextEditingController(text: 'Flutter, Kotlin, Android');
  final _instructions = TextEditingController(text: 'Загрузите ZIP проекта или ссылку на публичный Git-репозиторий. README и тесты обязательны.');

  // Список конфигураций чекеров. Инициализируется дефолтными значениями.
  var _checkers = [...defaultCheckerConfig];

  var _loading = false; // Флаг состояния загрузки (блокировка UI)
  String? _error; // Текст ошибки валидации или ответа сервера

  /// Вычисляет сумму весов всех включенных чекеров.
  /// Используется для валидации (сумма должна быть ровно 100).
  int get _totalWeight => _checkers.where((item) => item.enabled).fold(0, (sum, item) => sum + item.weight);

  @override
  void dispose() {
    // Освобождение ресурсов контроллеров при уничтожении виджета
    _title.dispose();
    _description.dispose();
    _technologies.dispose();
    _instructions.dispose();
    super.dispose();
  }

  /// Обновляет конфигурацию конкретного чекера в списке.
  /// Создает новый список, заменяя старый объект на обновленный.
  void _updateChecker(CheckerName checker, CheckerConfig next) {
    setState(() {
      _checkers = _checkers.map((item) => item.checker == checker ? next : item).toList();
    });
  }

  /// Отправляет данные на сервер для создания задания.
  /// [status] определяет, будет ли задание сохранено как черновик или опубликовано.
  Future<void> _submit(AssignmentStatus status) async {
    // --- Валидация на клиенте ---
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Введите название задания');
      return;
    }
    if (_totalWeight != 100) {
      setState(() => _error = 'Сумма весов активных чекеров должна быть 100%');
      return;
    }

    // --- Подготовка к запросу ---
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      // Логирование начала операции
      AppLogger.info('CreateAssignmentScreen', 'Assignment create started', {
        'title': _title.text.trim(),
        'totalWeight': _totalWeight,
      });

      // Парсинг технологий из строки "A, B, C" в список ["A", "B", "C"]
      final techList = _technologies.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

      // Вызов метода репозитория для создания задания
      await _repository.createAssignment(
        checkerConfig: _checkers,
        description: _description.text.trim(),
        instructionsMarkdown: _instructions.text.trim(),
        status: status,
        technologies: techList,
        title: _title.text.trim(),
      );

      // Логирование успеха
      AppLogger.debug('CreateAssignmentScreen', 'Assignment create completed', {'status': status.name});

      if (!mounted) return;
      // Возвращаемся назад, передавая true (успех)
      Navigator.of(context).pop(true);
    } catch (error) {
      // Обработка ошибок сети или сервера
      AppLogger.error('CreateAssignmentScreen', 'Assignment create failed', error);
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      // Снятие блокировки UI независимо от результата
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      selected: 'create', // Подсветка пункта меню "Создать"
      onDashboard: () => Navigator.of(context).pop(), // Клик по лого/дашборду закрывает экран
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TechLabel('Sprint-3 / assignment control'),
          SizedBox(height: 18),

          // Заголовок экрана
          Text('Создание тестового задания', style: Theme.of(context).textTheme.displayLarge),
          SizedBox(height: 20),
          Text('Настройте чекеры и веса. Backend принимает задание только при сумме 100%.', style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 44),

          // --- Панель 1: Основные поля ---
          TechPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(label: 'Название задания', controller: _title),
                SizedBox(height: 18),
                _Field(label: 'Технологии', controller: _technologies),
                SizedBox(height: 18),
                _Field(label: 'Описание', controller: _description, lines: 4),
                SizedBox(height: 18),
                _Field(label: 'Инструкция кандидату', controller: _instructions, lines: 5),
              ],
            ),
          ),
          SizedBox(height: 28),

          // --- Панель 2: Чекеры и веса ---
          TechPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TechIcon(TechIconType.activity, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(child: Text('Чекеры и веса', style: Theme.of(context).textTheme.titleLarge)),
                    // Индикатор суммы весов: зеленый если 100, красный если нет
                    Text('$_totalWeight%', style: TechText.monoValue.copyWith(fontSize: 24, color: _totalWeight == 100 ? AppColors.accent : AppColors.danger)),
                  ],
                ),
                SizedBox(height: 22),

                // Генерация списка строк чекеров
                ..._checkers.map((item) => _CheckerRow(
                      config: item,
                      onChanged: (next) => _updateChecker(item.checker, next),
                    )),

                // Блок ошибки (если есть)
                if (_error != null) ...[
                  SizedBox(height: 18),
                  _ErrorPanel(_error!),
                ],

                SizedBox(height: 24),

                // Кнопки действий
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    TechButton(label: 'Отмена', variant: TechButtonVariant.ghost, onPressed: () => Navigator.of(context).pop(false)),
                    TechButton(label: 'Черновик', loading: _loading, variant: TechButtonVariant.secondary, onPressed: () => _submit(AssignmentStatus.draft)),
                    TechButton(icon: TechIconType.check, label: 'Опубликовать', loading: _loading, onPressed: () => _submit(AssignmentStatus.published)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Внутренние виджеты экрана
// ============================================================================

/// Строка настройки одного чекера.
/// Содержит чекбокс включения, название, текущий вес и слайдер регулировки.
class _CheckerRow extends StatelessWidget {
  const _CheckerRow({required this.config, required this.onChanged});

  final CheckerConfig config;
  final ValueChanged<CheckerConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panelDeep, border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: config.enabled,
                activeColor: AppColors.accent,
                onChanged: (value) => onChanged(config.copyWith(enabled: value ?? false)),
              ),
              Expanded(child: Text(checkerLabel(config.checker), style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800))),
              Text('${config.weight}%', style: TechText.label.copyWith(color: AppColors.accent)),
            ],
          ),
          Slider(
            value: config.weight.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            // Слайдер активен только если чекер включен
            onChanged: config.enabled ? (value) => onChanged(config.copyWith(weight: value.round())) : null,
          ),
        ],
      ),
    );
  }
}

/// Универсальное поле ввода с лейблом.
class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.lines = 1});

  final TextEditingController controller;
  final String label;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(label),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: lines,
          style: TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.panelDeep,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, // Sharp corners
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
      ],
    );
  }
}

/// Панель отображения ошибки.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), border: Border.all(color: AppColors.danger.withOpacity(0.35))),
      child: Text(text, style: TextStyle(color: AppColors.orange)),
    );
  }
}
