import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_service.dart';
import '../domain/auth_validation.dart';
import 'account_flow.dart';
import 'auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// Log in with email and password. Loading shows on the button; an error
/// shows as a banner, never both at once.
class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  var _attempted = false;
  var _loading = false;
  AuthFailure? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _emailError => _attempted ? validateEmail(_email.text) : null;
  String? get _passwordError =>
      _attempted && _password.text.isEmpty ? 'Enter your password.' : null;

  Future<void> _submit() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    if (validateEmail(_email.text) != null || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = await ref
          .read(authServiceProvider)
          .logIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      await finishLogin(context, ref, user);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(authServiceProvider).isConfigured;
    final enabled = configured && !_loading;
    return Scaffold(
      appBar: AuthTopBar(
        trailing: AuthLink(
          label: 'Sign up',
          onPressed: () => context.pushReplacement(AppRoutes.createAccount),
        ),
      ),
      body: ListView(
        padding: authPadding,
        children: [
          if (!configured) ...[
            const AccountsUnavailableBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          const AuthHeading(
            icon: Icons.login_rounded,
            title: 'Welcome back',
            subtitle: 'Log in to continue your IELTS prep.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error case final error? when !_loading) ...[
            InfoBanner(
              key: const ValueKey('loginError'),
              type: InfoBannerType.error,
              message: error.message,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const GoogleComingSoonButton(),
          const SizedBox(height: AppSpacing.md),
          const OrDivider(label: 'or log in with email'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('emailField'),
            label: 'Email address',
            controller: _email,
            enabled: enabled,
            errorText: _emailError,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('passwordField'),
            label: 'Password',
            controller: _password,
            isPassword: true,
            enabled: enabled,
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => setState(() {}),
            onSubmitted: enabled ? (_) => _submit() : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AuthLink(
              label: 'Forgot password?',
              onPressed: configured
                  ? () => context.push(
                      AppRoutes.forgotPasswordWith(_email.text.trim()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            key: const ValueKey('logInButton'),
            label: _loading ? 'Logging in…' : 'Log in',
            isLoading: _loading,
            onPressed: enabled ? _submit : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthFooter(
            question: "Don't have an account?",
            action: 'Sign up',
            onPressed: () => context.pushReplacement(AppRoutes.createAccount),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Logging in syncs your progress with your account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
