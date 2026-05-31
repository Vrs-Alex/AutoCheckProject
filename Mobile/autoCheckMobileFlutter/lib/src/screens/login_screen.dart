import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../services/app_logger.dart';
import '../services/backend_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tech_background.dart';
import '../widgets/tech_components.dart';
import '../widgets/tech_icon.dart';
import 'dashboard_screen.dart';

/// Экран авторизации эксперта с demo credentials и логированием входа.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'expert@autocheck.local');
  final _fullNameController = TextEditingController(text: 'Алексей Морозов');
  final _passwordController = TextEditingController(text: 'secret123');
  final _repository = BackendRepository.instance;

  bool _loading = false;
  String? _error;
  UserRole _role = UserRole.expert;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppLogger.debug('LoginScreen', 'Client validation blocked login', {
        'emailEmpty': email.isEmpty,
        'passwordEmpty': password.isEmpty,
      });
      setState(() => _error = 'Заполните email и пароль');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      AppLogger.info('LoginScreen', 'Login request started', {'email': email});
      await _repository.login(email, password);
      AppLogger.debug('LoginScreen', 'Login request completed', {'email': email});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (error) {
      AppLogger.error('LoginScreen', 'Login request failed', error);
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || fullName.isEmpty || password.length < 6) {
      setState(() => _error = 'Заполните email, ФИО и пароль от 6 символов');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      AppLogger.info('LoginScreen', 'Register request started', {'email': email, 'role': _role.name});
      await _repository.register(email: email, fullName: fullName, password: password, role: _role);
      AppLogger.debug('LoginScreen', 'Register request completed', {'email': email});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (error) {
      AppLogger.error('LoginScreen', 'Register request failed', error);
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TechBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    return TechPanel(
                      padding: EdgeInsets.zero,
                      child: IntrinsicHeight(
                        child: Flex(
                          direction: wide ? Axis.horizontal : Axis.vertical,
                          children: [
                            if (wide)
                              const Expanded(
                                flex: 11,
                                child: _LoginHero(),
                              ),
                            if (wide)
                              Expanded(
                                flex: 9,
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: _LoginForm(
                                    emailController: _emailController,
                                    error: _error,
                                    fullNameController: _fullNameController,
                                    loading: _loading,
                                    onDemo: (account) {
                                      AppLogger.debug(
                                        'LoginScreen',
                                        'Demo account selected',
                                        {'email': account.email},
                                      );
                                      _emailController.text = account.email;
                                      _fullNameController.text = account.fullName;
                                      _passwordController.text = account.password;
                                      setState(() => _role = account.role);
                                    },
                                    onRegister: _register,
                                    onRoleChanged: (role) => setState(() => _role = role),
                                    onSubmit: _submit,
                                    passwordController: _passwordController,
                                    role: _role,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(28),
                                child: _LoginForm(
                                  emailController: _emailController,
                                  error: _error,
                                  fullNameController: _fullNameController,
                                  loading: _loading,
                                  onDemo: (account) {
                                    AppLogger.debug(
                                      'LoginScreen',
                                      'Demo account selected',
                                      {'email': account.email},
                                    );
                                    _emailController.text = account.email;
                                    _fullNameController.text = account.fullName;
                                    _passwordController.text = account.password;
                                    setState(() => _role = account.role);
                                  },
                                  onRegister: _register,
                                  onRoleChanged: (role) => setState(() => _role = role),
                                  onSubmit: _submit,
                                  passwordController: _passwordController,
                                  role: _role,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundAlt,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.border),
                ),
                child: const TechIcon(
                  TechIconType.clipboard,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'AutoCheck',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'monospace',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 96),
          Text(
            'Панель автопроверки мобильных тестовых заданий',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 28),
          const Text(
            'Создавайте задания, загружайте решения, наблюдайте за чекерами и фиксируйте итоговый вердикт в одном интерфейсе.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 18,
              height: 1.65,
            ),
          ),
          const Spacer(),
          const TechLabel('[ AUTH NODE: BACKEND / PORT 8080 ]'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 7,
                width: 7,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              const Text(
                'Session broker ready',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.email,
    required this.fullName,
    required this.label,
    required this.password,
    required this.role,
  });

  static const expert = _DemoAccount(
    email: 'expert@autocheck.local',
    fullName: 'Алексей Морозов',
    label: 'Эксперт',
    password: 'secret123',
    role: UserRole.expert,
  );

  static const candidate = _DemoAccount(
    email: 'candidate@autocheck.local',
    fullName: 'Иван Петров',
    label: 'Кандидат',
    password: 'secret123',
    role: UserRole.candidate,
  );

  final String email;
  final String fullName;
  final String label;
  final String password;
  final UserRole role;
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.fullNameController,
    required this.loading,
    required this.onDemo,
    required this.onRegister,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.passwordController,
    required this.role,
    this.error,
  });

  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final bool loading;
  final String? error;
  final ValueChanged<_DemoAccount> onDemo;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onRegister;
  final VoidCallback onSubmit;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const TechLabel('Вход в систему'),
        const SizedBox(height: 16),
        Text(
          'Экспертский dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          'Войдите в живой backend или создайте демо-пользователя в PostgreSQL.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _DemoCard(
                account: _DemoAccount.expert,
                onTap: () => onDemo(_DemoAccount.expert),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DemoCard(
                account: _DemoAccount.candidate,
                onTap: () => onDemo(_DemoAccount.candidate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _TechTextField(
          controller: emailController,
          icon: TechIconType.mail,
          label: 'Email',
        ),
        const SizedBox(height: 18),
        _TechTextField(
          controller: fullNameController,
          icon: TechIconType.user,
          label: 'ФИО',
        ),
        const SizedBox(height: 18),
        _TechTextField(
          controller: passwordController,
          icon: TechIconType.lock,
          label: 'Пароль',
          obscureText: true,
        ),
        const SizedBox(height: 18),
        Row(
          children: UserRole.values.map((item) {
            final active = role == item;
            return Expanded(
              child: InkWell(
                onTap: () => onRoleChanged(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : AppColors.panelDeep,
                    border: Border.all(color: active ? AppColors.accent : AppColors.border),
                  ),
                  child: Text(
                    item == UserRole.expert ? 'Эксперт' : 'Кандидат',
                    textAlign: TextAlign.center,
                    style: TechText.label.copyWith(color: active ? AppColors.background : AppColors.muted),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              border: Border.all(color: AppColors.danger.withOpacity(0.35)),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFFF7A3D)),
            ),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: TechButton(
            label: 'Войти',
            loading: loading,
            onPressed: onSubmit,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TechButton(
            label: 'Создать пользователя',
            loading: loading,
            onPressed: onRegister,
            variant: TechButtonVariant.secondary,
          ),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.account,
    required this.onTap,
  });

  final _DemoAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                account.label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                account.email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.dim),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechTextField extends StatelessWidget {
  const _TechTextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final TechIconType icon;
  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.panelDeep,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: TechIcon(icon, color: AppColors.dim, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}
