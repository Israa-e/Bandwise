import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_service.dart';
import '../../domain/auth_validation.dart';

/// Page padding for the auth screens.
const authPadding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.sm,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// An icon badge, the screen title and a line under it.
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: AppRadii.nestedRadius,
          ),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.headlineLg),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Shown on every auth screen when the build has no Supabase keys.
class AccountsUnavailableBanner extends StatelessWidget {
  const AccountsUnavailableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      key: const ValueKey('accountsUnavailable'),
      type: InfoBannerType.warning,
      icon: Icons.cloud_off_rounded,
      title: AuthErrorKind.notConfigured.message,
      message:
          'You can keep using Bandwise as a guest. Your progress stays '
          'on this device.',
    );
  }
}

/// Google sign-in isn't set up yet.
class GoogleComingSoonButton extends StatelessWidget {
  const GoogleComingSoonButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Continue with Google, coming soon',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('googleButton'),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadii.buttonRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.g_mobiledata_rounded,
              size: 28,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Continue with Google',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const AppPill(
              label: 'Coming soon',
              size: AppPillSize.small,
              background: AppColors.disabledFill,
              foreground: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// "or continue with email" between two rules.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.smd,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

/// Four segments and a label for [passwordStrength].
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    final color = switch (strength) {
      PasswordStrength.tooShort || PasswordStrength.weak => AppColors.error,
      PasswordStrength.fair => AppColors.warning,
      PasswordStrength.strong => AppColors.success,
    };
    final filled = password.isEmpty ? 0 : strength.level + 1;
    final label = password.isEmpty
        ? '$minPasswordLength+ characters, with letters and numbers'
        : strength.label;
    return Semantics(
      liveRegion: true,
      label: 'Password strength: $label',
      excludeSemantics: true,
      child: Column(
        key: const ValueKey('strengthMeter'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < filled ? color : AppColors.track,
                      borderRadius: AppRadii.pillRadius,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            key: const ValueKey('strengthLabel'),
            style: AppTextStyles.labelSm.copyWith(
              color: password.isEmpty ? AppColors.textMuted : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// A text link styled as a small button, e.g. "Forgot password?".
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs,
        ),
      ),
      child: Text(label),
    );
  }
}

/// "Already have an account? Log in" style footer.
class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
        AuthLink(label: action, onPressed: onPressed),
      ],
    );
  }
}
