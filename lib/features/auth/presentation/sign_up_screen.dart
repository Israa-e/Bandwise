import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/auth_service.dart';
import '../domain/auth_validation.dart';
import 'account_flow.dart';
import 'auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// Create an account: name, email, password with a strength meter, and the
/// terms checkbox (unchecked until the learner ticks it).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _acceptedTerms = false;

  /// Field errors show after the first attempt.
  var _attempted = false;
  var _loading = false;
  AuthFailure? _error;

  /// Set when the account needs email confirmation.
  String? _confirmationSentTo;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _nameError => _attempted ? validateName(_name.text) : null;
  String? get _emailError => _attempted ? validateEmail(_email.text) : null;
  String? get _passwordError =>
      _attempted ? validateNewPassword(_password.text) : null;

  Future<void> _submit() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    if (validateName(_name.text) != null ||
        validateEmail(_email.text) != null ||
        validateNewPassword(_password.text) != null) {
      return;
    }
    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      final outcome = await auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      final user = auth.currentUser;
      if (outcome == SignUpOutcome.signedIn && user != null) {
        await finishSignUp(context, ref, user);
      } else {
        setState(() => _confirmationSentTo = _email.text.trim());
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _confirmationSentTo;
    return Scaffold(
      appBar: AuthTopBar(
        trailing: sentTo == null
            ? AuthLink(
                label: 'Log in',
                onPressed: () => context.pushReplacement(AppRoutes.login),
              )
            : null,
      ),
      body: sentTo == null ? _form() : _CheckInbox(email: sentTo),
    );
  }

  Widget _form() {
    final configured = ref.watch(authServiceProvider).isConfigured;
    final enabled = configured && !_loading;
    return ListView(
      padding: authPadding,
      children: [
        if (!configured) ...[
          const AccountsUnavailableBanner(),
          const SizedBox(height: AppSpacing.lg),
        ],
        const AuthHeading(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Create your account',
          subtitle:
              'Save your IELTS study plan and sync your progress across '
              'devices.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const GoogleComingSoonButton(),
        const SizedBox(height: AppSpacing.md),
        const OrDivider(label: 'or continue with email'),
        const SizedBox(height: AppSpacing.md),
        if (_error case final error?) ...[
          InfoBanner(
            key: const ValueKey('signUpError'),
            type: InfoBannerType.error,
            message: error.message,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          key: const ValueKey('nameField'),
          label: 'Full name',
          controller: _name,
          enabled: enabled,
          errorText: _nameError,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const ValueKey('emailField'),
          label: 'Email address',
          controller: _email,
          enabled: enabled,
          errorText: _emailError,
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
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        PasswordStrengthMeter(password: _password.text),
        const SizedBox(height: AppSpacing.md),
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: const ValueKey('termsCheckbox'),
                value: _acceptedTerms,
                onChanged: enabled
                    ? (v) => setState(() => _acceptedTerms = v ?? false)
                    : null,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: enabled
                      ? () => setState(() => _acceptedTerms = !_acceptedTerms)
                      : null,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(top: 12),
                    child: Text(
                      'I agree to the Terms of Use and the Privacy Policy.',
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          key: const ValueKey('createAccountButton'),
          label: 'Create account',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: _loading,
          // The terms must be accepted first.
          onPressed: enabled && _acceptedTerms ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthFooter(
          question: 'Already have an account?',
          action: 'Log in',
          onPressed: () => context.pushReplacement(AppRoutes.login),
        ),
        // From the end of onboarding: an account is optional.
        if (!(ref.watch(onboardingControllerProvider).value?.completed ?? true))
          AppButton.ghost(
            key: const ValueKey('skipAccount'),
            label: 'Continue without an account',
            expand: true,
            onPressed: _loading ? null : _continueAsGuest,
          ),
      ],
    );
  }

  Future<void> _continueAsGuest() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.home);
  }
}

/// Email confirmation is on: the account is created but not signed in.
class _CheckInbox extends ConsumerWidget {
  const _CheckInbox({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed =
        ref.watch(onboardingControllerProvider).value?.completed ?? false;
    return ListView(
      key: const ValueKey('checkInbox'),
      padding: authPadding,
      children: [
        const AuthHeading(
          icon: Icons.mark_email_read_outlined,
          title: 'Check your inbox to confirm your email',
          subtitle:
              'Open the link in the email, then come back and log in. If it '
              "doesn't arrive in a few minutes, check your spam folder.",
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Sent to $email', style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: 'Log in',
          onPressed: () => context.pushReplacement(AppRoutes.loginWith(email)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (completed)
          AppButton.ghost(
            label: 'Back',
            expand: true,
            onPressed: () => context.pop(),
          )
        else
          AppButton.ghost(
            label: 'Continue as a guest for now',
            expand: true,
            onPressed: () async {
              await ref.read(onboardingControllerProvider.notifier).complete();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
      ],
    );
  }
}
