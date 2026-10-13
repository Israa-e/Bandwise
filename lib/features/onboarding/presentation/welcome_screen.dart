import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';
import 'widgets/learning_path_illustration.dart';
import '../domain/onboarding_state.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, bool asGuest) async {
    await ref
        .read(onboardingControllerProvider.notifier)
        .start(asGuest: asGuest);
    if (context.mounted) {
      context.go(onboardingPath(OnboardingStep.targetBand));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          children: [
            const _BrandRow(),
            const SizedBox(height: AppSpacing.xl),
            const LearningPathIllustration(),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: const Text.rich(
                TextSpan(
                  text: 'Master IELTS Academic,\n',
                  children: [
                    TextSpan(
                      text: 'one step at a time.',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                style: AppTextStyles.headlineXl,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Bite-sized daily practice tailored to your target band score '
              '(6.0 – 8.0+).',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final skill in Skill.values)
                  SkillChip(skill: skill, size: AppPillSize.small),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton.primary(
              label: 'Sign up with email',
              leadingIcon: Icons.mail_outline_rounded,
              onPressed: () => _start(context, ref, false),
            ),
            const SizedBox(height: AppSpacing.smd),
            AppButton.outline(
              label: 'Log in',
              onPressed: () => context.push(AppRoutes.login),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: AppButton.ghost(
                label: 'Continue as guest',
                onPressed: () => _start(context, ref, true),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Independent preparation app. Not affiliated with IELTS, the '
              'British Council, IDP, or Cambridge.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 40),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bandwise',
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'ACADEMIC',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
