import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../services/app_logger.dart';
import '../services/backend_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/tech_components.dart';
import '../widgets/tech_icon.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _repository = BackendRepository.instance;
  final _title = TextEditingController(text: 'Mobile Clean Architecture Challenge');
  final _description = TextEditingController(text: 'Проверка мобильного проекта на архитектуру, сборку, тесты и документацию.');
  final _technologies = TextEditingController(text: 'Flutter, Kotlin, Android');
  final _instructions = TextEditingController(text: 'Загрузите ZIP проекта или ссылку на публичный Git-репозиторий. README и тесты обязательны.');

  var _checkers = [...defaultCheckerConfig];
  var _loading = false;
  String? _error;

  int get _totalWeight => _checkers.where((item) => item.enabled).fold(0, (sum, item) => sum + item.weight);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _technologies.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _updateChecker(CheckerName checker, CheckerConfig next) {
    setState(() {
      _checkers = _checkers.map((item) => item.checker == checker ? next : item).toList();
    });
  }

  Future<void> _submit(AssignmentStatus status) async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Введите название задания');
      return;
    }
    if (_totalWeight != 100) {
      setState(() => _error = 'Сумма весов активных чекеров должна быть 100%');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      AppLogger.info('CreateAssignmentScreen', 'Assignment create started', {
        'title': _title.text.trim(),
        'totalWeight': _totalWeight,
      });
      await _repository.createAssignment(
        checkerConfig: _checkers,
        description: _description.text.trim(),
        instructionsMarkdown: _instructions.text.trim(),
        status: status,
        technologies: _technologies.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
        title: _title.text.trim(),
      );
      AppLogger.debug('CreateAssignmentScreen', 'Assignment create completed', {'status': status.name});
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      AppLogger.error('CreateAssignmentScreen', 'Assignment create failed', error);
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      selected: 'create',
      onDashboard: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TechLabel('Sprint-3 / assignment control'),
          const SizedBox(height: 18),
          Text('Создание тестового задания', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 20),
          const Text('Настройте чекеры и веса. Backend принимает задание только при сумме 100%.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 44),
          TechPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(label: 'Название задания', controller: _title),
                const SizedBox(height: 18),
                _Field(label: 'Технологии', controller: _technologies),
                const SizedBox(height: 18),
                _Field(label: 'Описание', controller: _description, lines: 4),
                const SizedBox(height: 18),
                _Field(label: 'Инструкция кандидату', controller: _instructions, lines: 5),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TechPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const TechIcon(TechIconType.activity, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Чекеры и веса', style: Theme.of(context).textTheme.titleLarge)),
                    Text('$_totalWeight%', style: TechText.monoValue.copyWith(fontSize: 24, color: _totalWeight == 100 ? AppColors.accent : AppColors.danger)),
                  ],
                ),
                const SizedBox(height: 22),
                ..._checkers.map((item) => _CheckerRow(
                      config: item,
                      onChanged: (next) => _updateChecker(item.checker, next),
                    )),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorPanel(_error!),
                ],
                const SizedBox(height: 24),
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

class _CheckerRow extends StatelessWidget {
  const _CheckerRow({required this.config, required this.onChanged});

  final CheckerConfig config;
  final ValueChanged<CheckerConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Expanded(child: Text(checkerLabel(config.checker), style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800))),
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
            onChanged: config.enabled ? (value) => onChanged(config.copyWith(weight: value.round())) : null,
          ),
        ],
      ),
    );
  }
}

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
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: lines,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.panelDeep,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), border: Border.all(color: AppColors.danger.withOpacity(0.35))),
      child: Text(text, style: const TextStyle(color: Color(0xFFFF7A3D))),
    );
  }
}
