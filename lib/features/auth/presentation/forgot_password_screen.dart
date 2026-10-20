import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_service.dart';
import '../domain/auth_validation.dart';
import 'account_flow.dart';
import 'auth_providers.dart';
import 'widgets/auth_widgets.dart';

enum _Step { email, code, done }

/// Password reset with a 6-digit code, so no deep links are needed:
/// email → code and new password → done (signed in).
///
/// The copy never says whether an account exists for the email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  var _step = _Step.email;
  var _attempted = false;
  var _loading = false;
  AuthFailure? _error;

  /// Signed in by the code; kept so a failed password change can be retried
  /// without a new code.
  AuthUser? _verified;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  AuthService get _auth => ref.read(authServiceProvider);

  Future<void> _busy(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    setState(() => _attempted = true);
    if (validateEmail(_email.text) != null) return;
    await _busy(() async {
      await _auth.sendPasswordResetCode(_email.text);
      if (mounted) {
        setState(() {
          _step = _Step.code;
          _attempted = false;
        });
      }
    });
  }

  Future<void> _resend() => _busy(() async {
    await _auth.sendPasswordResetCode(_email.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(_sentMessage(_email.text.trim(), again: true))),
      );
  });

  Future<void> _reset() async {
    setState(() => _attempted = true);
    if ((_verified == null && validateResetCode(_code.text) != null) ||
        validateNewPassword(_password.text) != null) {
      return;
    }
    await _busy(() async {
      _verified ??= await _auth.verifyResetCode(
        email: _email.text,
        code: _code.text,
      );
      await _auth.updatePassword(_password.text);
      if (mounted) setState(() => _step = _Step.done);
    });
  }

  static String _sentMessage(String email, {bool again = false}) =>
      'If an account exists for $email, we’ve sent ${again ? 'a new' : 'a'} '
      '6-digit code. It can take a few minutes and may land in spam.';

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(authServiceProvider).isConfigured;
    return Scaffold(
      appBar: const AuthTopBar(),
      body: ListView(
        padding: authPadding,
        children: [
          if (!configured) ...[
            const AccountsUnavailableBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          ...switch (_step) {
            _Step.email => _emailStep(configured),
            _Step.code => _codeStep(),
            _Step.done => _doneStep(),
          },
        ],
      ),
    );
  }

  Widget? _errorBanner() => _error == null
      ? null
      : Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
          child: InfoBanner(
            key: const ValueKey('resetError'),
            type: InfoBannerType.error,
            message: _error!.message,
          ),
        );

  List<Widget> _emailStep(bool configured) => [
    const AuthHeading(
      icon: Icons.lock_reset_rounded,
      title: 'Reset your password',
      subtitle: 'Enter your email and we’ll send you a 6-digit code.',
    ),
    const SizedBox(height: AppSpacing.lg),
    ?_errorBanner(),
    AppTextField(
      key: const ValueKey('resetEmailField'),
      label: 'Email address',
      controller: _email,
      enabled: configured && !_loading,
      errorText: _attempted ? validateEmail(_email.text) : null,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: AppSpacing.lg),
    AppButton.primary(
      key: const ValueKey('sendCodeButton'),
      label: 'Send code',
      isLoading: _loading,
      onPressed: configured && !_loading ? _sendCode : null,
    ),
  ];

  List<Widget> _codeStep() => [
    AuthHeading(
      icon: Icons.mark_email_read_outlined,
      title: 'Enter your code',
      subtitle: _sentMessage(_email.text.trim()),
    ),
    const SizedBox(height: AppSpacing.lg),
    ?_errorBanner(),
    if (_verified == null) ...[
      AppTextField(
        key: const ValueKey('codeField'),
        label: '6-digit code',
        controller: _code,
        enabled: !_loading,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        errorText: _attempted ? validateResetCode(_code.text) : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
    AppTextField(
      key: const ValueKey('newPasswordField'),
      label: 'New password',
      controller: _password,
      isPassword: true,
      enabled: !_loading,
      autofillHints: const [AutofillHints.newPassword],
      errorText: _attempted ? validateNewPassword(_password.text) : null,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: AppSpacing.sm),
    PasswordStrengthMeter(password: _password.text),
    const SizedBox(height: AppSpacing.lg),
    AppButton.primary(
      key: const ValueKey('resetButton'),
      label: 'Reset password',
      isLoading: _loading,
      onPressed: _loading ? null : _reset,
    ),
    if (_verified == null) ...[
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          AuthLink(
            label: 'Send a new code',
            onPressed: _loading ? null : _resend,
          ),
          AuthLink(
            label: 'Use a different email',
            onPressed: _loading
                ? null
                : () => setState(() {
                    _step = _Step.email;
                    _code.clear();
                    _error = null;
                    _attempted = false;
                  }),
          ),
        ],
      ),
    ],
  ];

  List<Widget> _doneStep() => [
    const AuthHeading(
      icon: Icons.check_circle_outline_rounded,
      title: 'Password updated',
      subtitle: 'You’re logged in with your new password.',
    ),
    const SizedBox(height: AppSpacing.xl),
    AppButton.primary(
      key: const ValueKey('resetContinue'),
      label: 'Continue',
      isLoading: _loading,
      onPressed: _loading
          ? null
          : () => _busy(() => finishLogin(context, ref, _verified!)),
    ),
  ];
}
