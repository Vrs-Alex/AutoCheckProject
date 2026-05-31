import 'package:flutter/material.dart';
import '../models/submission.dart';
import '../services/app_logger.dart';
import '../services/backend_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/tech_components.dart';
import '../widgets/tech_icon.dart';
import 'submission_details_screen.dart';

class UploadSubmissionScreen extends StatefulWidget {
  const UploadSubmissionScreen({super.key});

  @override
  State<UploadSubmissionScreen> createState() => _UploadSubmissionScreenState();
}

class _UploadSubmissionScreenState extends State<UploadSubmissionScreen> {
  final _repository = BackendRepository.instance;
  final _candidateName = TextEditingController(text: 'Иван Петров');
  final _candidateEmail = TextEditingController(text: 'ivan.petrov@test.ru');
  final _gitUrl = TextEditingController();

  late Future<List<Assignment>> _assignmentsFuture;
  String? _assignmentId;
  SourceType _sourceType = SourceType.zip;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _repository.assignments();
  }

  @override
  void dispose() {
    _candidateName.dispose();
    _candidateEmail.dispose();
    _gitUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_assignmentId == null || _assignmentId!.isEmpty) {
      setState(() => _error = 'Выберите тестовое задание');
      return;
    }
    if (_candidateName.text.trim().isEmpty || !_candidateEmail.text.contains('@')) {
      setState(() => _error = 'Введите ФИО и корректный email кандидата');
      return;
    }
    if (_sourceType == SourceType.git && !_gitUrl.text.trim().startsWith('http')) {
      setState(() => _error = 'Введите публичный Git URL');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      AppLogger.info('UploadSubmissionScreen', 'Submission upload started', {
        'assignmentId': _assignmentId,
        'sourceType': _sourceType.name,
      });
      final submission = await _repository.createSubmission(
        assignmentId: _assignmentId!,
        candidateEmail: _candidateEmail.text.trim(),
        candidateFullName: _candidateName.text.trim(),
        gitUrl: _sourceType == SourceType.git ? _gitUrl.text.trim() : null,
      );
      AppLogger.debug('UploadSubmissionScreen', 'Submission upload completed', {'submissionId': submission.id});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SubmissionDetailsScreen(submissionId: submission.id),
        ),
      );
    } catch (error) {
      AppLogger.error('UploadSubmissionScreen', 'Submission upload failed', error);
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      selected: 'upload',
      onDashboard: () => Navigator.of(context).pop(),
      child: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const TechPanel(
              child: SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 1.5))),
            );
          }
          final assignments = snapshot.data!;
          _assignmentId ??= assignments.isEmpty ? null : assignments.first.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               TechLabel('Sprint-2 / intake terminal'),
               SizedBox(height: 18),
              Text('Загрузка решения', style: Theme.of(context).textTheme.displayLarge),
               SizedBox(height: 20),
               Text('Отправьте ZIP-архив или Git URL прямо в backend. Проверка попадет в Redis-очередь.', style: TextStyle(color: AppColors.muted)),
               SizedBox(height: 44),
              TechPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechLabel('Тестовое задание'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _assignmentId,
                      dropdownColor: AppColors.panel,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.panelDeep,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.accent)),
                      ),
                      items: assignments.map((item) => DropdownMenuItem(value: item.id, child: Text(item.title))).toList(),
                      onChanged: (value) => setState(() => _assignmentId = value),
                    ),
                     SizedBox(height: 18),
                    _Field(label: 'ФИО кандидата', controller: _candidateName),
                     SizedBox(height: 18),
                    _Field(label: 'Email кандидата', controller: _candidateEmail),
                     SizedBox(height: 22),
                    _SourceSwitch(value: _sourceType, onChanged: (value) => setState(() => _sourceType = value)),
                     SizedBox(height: 22),
                      _Field(label: 'Git URL', controller: _gitUrl),
                    if (_error != null) ...[
                       SizedBox(height: 18),
                      _ErrorPanel(_error!),
                    ],
                     SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        TechButton(label: 'Отмена', variant: TechButtonVariant.ghost, onPressed: () => Navigator.of(context).pop(false)),
                        TechButton(icon: TechIconType.upload, label: 'Отправить', loading: _loading, onPressed: _submit),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceSwitch extends StatelessWidget {
  const _SourceSwitch({required this.onChanged, required this.value});

  final SourceType value;
  final ValueChanged<SourceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SourceType.values.map((item) {
        final active = value == item;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(item),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.panelDeep,
                border: Border.all(color: active ? AppColors.accent : AppColors.border),
              ),
              child: Text(
                item == SourceType.zip ? 'ZIP-файл' : 'Git URL',
                textAlign: TextAlign.center,
                style: TechText.label.copyWith(color: active ? AppColors.background : AppColors.muted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
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
      padding:  EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), border: Border.all(color: AppColors.danger.withOpacity(0.35))),
      child: Text(text, style:  TextStyle(color: Color(0xFFFF7A3D))),
    );
  }
}
