import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// What is stored, and how AI review will handle essays and recordings.
/// Static text.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TabTopBar(title: 'Privacy and AI', showBack: true),
      body: ListView(
        padding: _padding,
        children: [
          const _Section(
            title: 'Stored on this device',
            icon: Icons.phone_android_rounded,
            points: [
              'Your study plan: goal, exam date, daily time, focus skills '
                  'and level.',
              'Your progress: lessons, XP, streak, study time, mistakes, '
                  'reviews and reading attempts.',
              'Essays you write, with their drafts and feedback.',
              'Settings such as the daily reminder time.',
            ],
            footer:
                'Nothing is sent to a server yet. You can delete it all '
                'from Profile › Delete all data.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _Section(
            title: 'AI review',
            icon: Icons.auto_awesome_outlined,
            points: [
              "AI review isn't connected yet. Your own essays get general "
                  'demo feedback with no estimate.',
              'The sample essays show feedback prepared in advance, to '
                  'demonstrate how a review will look.',
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _Section(
            title: 'Once AI review is connected',
            icon: Icons.cloud_outlined,
            badge: 'Planned policy',
            points: [
              'Essays, and recordings once Speaking practice arrives, will '
                  'be sent to our server to generate feedback.',
              'The app will never contact an AI service directly; requests '
                  'go through our server.',
              'Your essays and recordings will never be used to train AI '
                  'models without your consent.',
            ],
            footer:
                'This is the planned policy. The Privacy Policy will set out '
                'the details before AI review starts.',
          ),
          const SizedBox(height: AppSpacing.xl),
          GroupCard(
            children: [
              AppListRow(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              AppListRow(
                icon: Icons.description_outlined,
                title: 'Terms of Use',
                onTap: () => context.push(AppRoutes.terms),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.points,
    this.badge,
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<String> points;
  final String? badge;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AppTextStyles.headlineSm),
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPill(
              label: badge!,
              size: AppPillSize.small,
              background: AppColors.warningTint,
              foreground: AppColors.text,
            ),
          ],
          for (final point in points)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: AppTextStyles.bodyMd),
                  Expanded(child: Text(point, style: AppTextStyles.bodyMd)),
                ],
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.smd),
            Text(
              footer!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
