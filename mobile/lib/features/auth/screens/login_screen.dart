import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/alpha_connect_logo.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final _codeControllers = List.generate(6, (_) => TextEditingController());

  bool _isOtpStep = false;
  bool _isSubmitting = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullCode =>
      _codeControllers.map((c) => c.text).join();

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authProvider.notifier)
        .requestCode(_emailController.text.trim());

    setState(() => _isSubmitting = false);

    if (result != null) {
      setState(() => _isOtpStep = true);
      _startResendCountdown();
      _codeFocusNodes.first.requestFocus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar código. Tente novamente.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) return;

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authProvider.notifier)
        .verifyCode(_emailController.text.trim(), code);

    setState(() => _isSubmitting = false);

    if (result == AuthVerifyResult.success) return;

    if (!mounted) return;

    final authState = ref.read(authProvider);
    String message = 'Erro desconhecido';
    if (authState is AuthError) {
      message = authState.message;
      if (authState.attemptsRemaining != null) {
        message =
            '$message (${authState.attemptsRemaining} tentativas restantes)';
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );

    if (result == AuthVerifyResult.maxAttempts) {
      for (final c in _codeControllers) {
        c.clear();
      }
      _startResendCountdown();
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() => _isSubmitting = true);
    await ref
        .read(authProvider.notifier)
        .requestCode(_emailController.text.trim());
    setState(() => _isSubmitting = false);
    _startResendCountdown();
  }

  /// Enter demo mode with a fake user (no backend needed).
  void _enterDemoMode(String role) {
    final demoUser = UserModel(
      id: 'demo-${role}-001',
      name: role == 'student' ? 'João Demo' : 'Admin Demo',
      email: role == 'student' ? 'joao@universidade.edu' : 'admin@universidade.edu',
      role: role,
    );
    ref.read(authProvider.notifier).setDemoUser(demoUser);
  }

  void _onCodeDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _codeControllers[i].text = digits[i];
      }
      final nextIndex = (digits.length < 6) ? digits.length : 5;
      _codeFocusNodes[nextIndex].requestFocus();
      if (digits.length >= 6) _verifyCode();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    }

    if (_fullCode.length == 6) {
      _verifyCode();
    }
  }

  void _onCodeKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _codeControllers[index].text.isEmpty &&
        index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          final next = isDark ? ThemeMode.light : ThemeMode.dark;
          ref.read(themeModeNotifierProvider.notifier).setThemeMode(next);
        },
        backgroundColor: colors.surfaceContainer,
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: colors.primary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isOtpStep ? _buildOtpStep() : _buildEmailStep(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_step'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo mark — perfectly upright, no rotation
          const AlphaConnectLogo(size: 80),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.xl),

          // Heading
          Text(
            'Entrar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Informe seu email acadêmico...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Email input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Email acadêmico',
              hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.email_outlined, color: colors.onSurfaceVariant),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email obrigatório';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Email inválido';
              }
              return null;
            },
            onFieldSubmitted: (_) => _requestCode(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _requestCode,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Enviar código'),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Demo mode buttons (for preview without backend)
          Divider(color: colors.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'MODO DEMONSTRAÇÃO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _enterDemoMode('student'),
                  child: const Text('Aluno', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _enterDemoMode('staff'),
                  child: const Text('Gestor', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('otp_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon badge
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(
            Icons.email_outlined,
            size: 48,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'CÓDIGO DE ACESSO',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.primary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Insira o código de 6 dígitos enviado para o seu email.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 6-digit code inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onCodeKeyEvent(index, event),
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6, // allow paste
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: colors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  onChanged: (value) => _onCodeDigitChanged(index, value),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _verifyCode,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Verificar Código'),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20,
                          color: Theme.of(context).colorScheme.onPrimary),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Back + Resend
        TextButton.icon(
          onPressed: () => setState(() {
            _isOtpStep = false;
            for (final c in _codeControllers) {
              c.clear();
            }
            _resendTimer?.cancel();
          }),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Voltar'),
        ),
        if (!_canResend)
          Text(
            'Reenviar código ($_resendCountdown s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          )
        else
          TextButton(
            onPressed: _resendCode,
            child: const Text('Reenviar código'),
          ),
      ],
    );
  }
}
