import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  bool _isOtpStep = false;
  bool _isSubmitting = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

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
      // Success — show OTP step
      setState(() => _isOtpStep = true);
      _startResendCountdown();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar codigo. Tente novamente.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authProvider.notifier)
        .verifyCode(_emailController.text.trim(), code);

    setState(() => _isSubmitting = false);

    if (result == AuthVerifyResult.success) {
      // Navigation handled by GoRouter redirect in Plan 03
      return;
    }

    if (!mounted) return;

    // Show error snackbar per D-10
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

    // If max attempts, restart countdown (new code auto-sent by backend)
    if (result == AuthVerifyResult.maxAttempts) {
      _codeController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/title area
                Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Desafio FCG3',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Plataforma Academica',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Two-step animated content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isOtpStep ? _buildOtpStep() : _buildEmailStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Entrar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Informe seu email institucional para receber o codigo de verificacao.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'aluno@universidade.edu',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email obrigatorio';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Email invalido';
              }
              return null;
            },
            onFieldSubmitted: (_) => _requestCode(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _requestCode,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar codigo'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _isOtpStep = false;
                _codeController.clear();
                _resendTimer?.cancel();
              }),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Verificar codigo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Digite o codigo de 6 digitos enviado para ${_emailController.text.trim()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            labelText: 'Codigo de verificacao',
            hintText: '000000',
            prefixIcon: Icon(Icons.lock_outlined),
            counterText: '',
          ),
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          onFieldSubmitted: (_) => _verifyCode(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _verifyCode,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verificar'),
        ),
        const SizedBox(height: 16),
        // Resend button with countdown per D-11
        TextButton(
          onPressed: _canResend ? _resendCode : null,
          child: Text(
            _canResend
                ? 'Reenviar codigo'
                : 'Reenviar codigo ($_resendCountdown s)',
          ),
        ),
      ],
    );
  }
}
