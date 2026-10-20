import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/presentation/progress_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../writing/presentation/writing_providers.dart';
import '../domain/achievements.dart';
import 'data_controls.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// The independence disclaimer.
const disclaimerText =
    'Bandwise is an independent app for IELTS Academic practice. It is not '
    'affiliated with, or endorsed by, IELTS, the British Council, IDP or '
    'Cambridge.';

/// The Profile tab: who you are, your plan, badges, settings and data.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan =
        ref.watch(onboardingControllerProvider).value ??
        const OnboardingState();
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: const TabTopBar(title: 'Profile'),
      body: ListView(
        padding: _padding,
        children: [
          _Header(plan: plan, today: today),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Study plan'),
          _StudyPlan(plan: plan, today: today),
          const SizedBox(height: AppSpacing.xl),
          const _Achievements(),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Settings'),
          _Settings(plan: plan),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Account'),
          const _AccountCard(),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Data and privacy'),
          const _DataAndPrivacy(),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('About'),
          const _About(),
        ],
      ),
    );
  }
}

/// "in 8 weeks" style countdown line for the exam, or that none is set.
String examLine(OnboardingState plan, DateTime today) {
  final date = plan.examDate;
  if (date == null) {
    return plan.examNotBooked ? 'Exam not booked yet' : 'No exam date set';
  }
  final until = timeUntilLabel(today, date);
  return until == 'today'
      ? 'Exam today'
      : 'Exam in $until · ${formatMediumDate(date)}';
}

String _minutesLine(OnboardingState plan) =>
    '${plan.dailyMinutes ?? OnboardingState.defaultDailyMinutes} min a day';

class _Header extends StatelessWidget {
  const _Header({required this.plan, required this.today});

  final OnboardingState plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final goal = plan.targetBand?.value;
    final level = plan.level;
    Widget line(IconData icon, String text, {Key? key}) => Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              key: key,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );

    return AppCard(
      key: const ValueKey('profileHeader'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No accounts yet, so there is no name to show.
                    Semantics(
                      header: true,
                      child: const Text(
                        'Guest',
                        key: ValueKey('profileName'),
                        style: AppTextStyles.headlineMd,
                      ),
                    ),
                    Text(
                      'Progress saved on this device',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goal != null) ...[
            const SizedBox(height: AppSpacing.smd),
            GoalChip(value: goal),
          ],
          const SizedBox(height: AppSpacing.xs),
          line(
            Icons.event_rounded,
            examLine(plan, today),
            key: const ValueKey('examLine'),
          ),
          line(
            Icons.schedule_rounded,
            'Daily goal: ${_minutesLine(plan)}',
            key: const ValueKey('dailyGoalLine'),
          ),
          line(
            Icons.signal_cellular_alt_rounded,
            level == null
                ? 'Level not set'
                : 'Level: ${level.label} (self-assessed)',
            key: const ValueKey('levelLine'),
          ),
        ],
      ),
    );
  }
}

class _StudyPlan extends StatelessWidget {
  const _StudyPlan({required this.plan, required this.today});

  final OnboardingState plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final goal = plan.targetBand?.value;
    final skills = plan.skills;
    void edit(String route) => context.push(route);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tap a part of your plan to edit it.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        GroupCard(
          children: [
            AppListRow(
              key: const ValueKey('editTarget'),
              icon: Icons.flag_outlined,
              title: 'Goal',
              subtitle: goal == null ? 'Not sure yet' : null,
              trailing: goal == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoalChip(value: goal),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
              onTap: () => edit(AppRoutes.editTarget),
            ),
            AppListRow(
              key: const ValueKey('editExamDate'),
              icon: Icons.event_outlined,
              title: 'Exam date',
              subtitle: examLine(plan, today),
              onTap: () => edit(AppRoutes.editExamDate),
            ),
            AppListRow(
              key: const ValueKey('editDailyTime'),
              icon: Icons.schedule_rounded,
              title: 'Daily time',
              subtitle: _minutesLine(plan),
              onTap: () => edit(AppRoutes.editDailyTime),
            ),
            AppListRow(
              key: const ValueKey('editSkills'),
              icon: Icons.tune_rounded,
              title: 'Focus skills',
              subtitle: skills.isEmpty
                  ? 'None chosen'
                  : [
                      for (final s in Skill.values)
                        if (skills.contains(s)) s.label,
                    ].join(', '),
              onTap: () => edit(AppRoutes.editSkills),
            ),
          ],
        ),
      ],
    );
  }
}

class _Achievements extends ConsumerWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final essays = ref.watch(writingSubmissionsProvider);
    final Widget content;
    if (progress.hasValue && essays.hasValue) {
      final badges = achievementsFor(
        progress.requireValue,
        essays.requireValue,
      );
      final earned = badges.where((b) => b.unlocked).length;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$earned of ${badges.length} earned. Badges show what you have '
            'done; they give no XP.',
            key: const ValueKey('badgeCount'),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < badges.length; i += 2) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _BadgeTile(badge: badges[i])),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: i + 1 < badges.length
                        ? _BadgeTile(badge: badges[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else if (progress.hasError || essays.hasError) {
      content = InfoBanner(
        type: InfoBannerType.error,
        message: "Couldn't load your achievements.",
        actionLabel: 'Retry',
        onAction: () => ref
          ..invalidate(progressControllerProvider)
          ..invalidate(writingSubmissionsProvider),
      );
    } else {
      content = const SkeletonCard(height: 120);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const SectionTitle('Achievements'), content],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final Achievement badge;

  static IconData _icon(AchievementKind kind) => switch (kind) {
    AchievementKind.firstLesson => Icons.school_rounded,
    AchievementKind.streak3 => Icons.local_fire_department_rounded,
    AchievementKind.streak7 => Icons.whatshot_rounded,
    AchievementKind.reviews50 => Icons.replay_rounded,
    AchievementKind.firstReading => Icons.menu_book_rounded,
    AchievementKind.perfectPassage => Icons.workspace_premium_rounded,
    AchievementKind.firstEssay => Icons.edit_note_rounded,
    AchievementKind.firstRevision => Icons.published_with_changes_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final kind = badge.kind;
    final earned = badge.earnedOn;
    final status = earned == null
        ? 'Locked. ${kind.howToEarn}'
        : 'Earned ${formatMediumDate(earned)}';
    return Semantics(
      label: '${kind.title}. $status',
      excludeSemantics: true,
      child: AppCard(
        key: ValueKey('badge-${kind.name}'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        color: earned == null ? AppColors.borderSubtle : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: earned == null
                    ? AppColors.disabledFill
                    : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                earned == null ? Icons.lock_outline_rounded : _icon(kind),
                size: 22,
                color: earned == null ? AppColors.textMuted : AppColors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(kind.title, style: AppTextStyles.labelLg),
            const SizedBox(height: 2),
            Text(
              earned == null
                  ? kind.howToEarn
                  : 'Earned ${formatMediumDate(earned)}',
              key: ValueKey('badgeStatus-${kind.name}'),
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Settings extends ConsumerWidget {
  const _Settings({required this.plan});

  final OnboardingState plan;

  Future<void> _pickTime(
    BuildContext context,
    OnboardingController controller,
    ReminderTime current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Daily reminder time',
    );
    if (picked != null) {
      await controller.setReminderTime(
        ReminderTime(picked.hour, picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final motion =
        ref.watch(settingsControllerProvider).value?.motion ??
        MotionPreference.system;
    final time = plan.reminderTime ?? OnboardingState.defaultReminderTime;
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final deviceReduces = View.of(
      context,
    ).platformDispatcher.accessibilityFeatures.disableAnimations;
    final muted = AppTextStyles.bodySm.copyWith(color: AppColors.textMuted);

    return GroupCard(
      children: [
        MergeSemantics(
          child: AppListRow(
            key: const ValueKey('reminderRow'),
            icon: Icons.notifications_none_rounded,
            title: 'Daily reminder',
            subtitle: plan.reminderEnabled ? 'Every day at $timeLabel' : 'Off',
            trailing: Switch(
              key: const ValueKey('reminderSwitch'),
              value: plan.reminderEnabled,
              onChanged: controller.setReminderEnabled,
            ),
          ),
        ),
        if (plan.reminderEnabled)
          AppListRow(
            key: const ValueKey('reminderTime'),
            title: 'Reminder time',
            subtitle: timeLabel,
            trailing: AppButton.ghost(
              label: 'Change',
              compact: true,
              onPressed: () => _pickTime(context, controller, time),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            'Reminders will start in a future update. Your time is saved.',
            style: muted,
          ),
        ),
        const AppListRow(
          icon: Icons.light_mode_outlined,
          title: 'Appearance',
          subtitle: 'Dark: coming soon',
          trailing: Text('Light', style: AppTextStyles.labelLg),
        ),
        Padding(
          key: const ValueKey('motionSetting'),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reduce motion', style: AppTextStyles.labelLg),
              const SizedBox(height: 2),
              Text(
                'Turns off celebrations and page animations. The device '
                'setting is ${deviceReduces ? 'on' : 'off'}.',
                style: muted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final m in MotionPreference.values)
                    AppFilterChip(
                      key: ValueKey('motion-${m.name}'),
                      label: m.label,
                      selected: m == motion,
                      onTap: () => ref
                          .read(settingsControllerProvider.notifier)
                          .setMotion(m),
                    ),
                ],
              ),
            ],
          ),
        ),
        const AppListRow(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'Arabic: coming soon',
          trailing: Text('English', style: AppTextStyles.labelLg),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('accountCard'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create an account to back up your progress',
            style: AppTextStyles.labelLg,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'For now everything is saved on this device only.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          AppButton.secondary(
            label: 'Create account',
            onPressed: () => context.push(AppRoutes.createAccount),
          ),
        ],
      ),
    );
  }
}

class _DataAndPrivacy extends ConsumerWidget {
  const _DataAndPrivacy();

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset progress?',
      message: 'This deletes your learning history on this device:',
      items: resetProgressItems,
      footnote: 'Your study plan and settings are kept.',
      confirmLabel: 'Reset progress',
    );
    if (!confirmed) return;
    await resetProgress(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Progress reset.')));
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete all data?',
      message: 'This deletes everything Bandwise saved on this device:',
      items: [...resetProgressItems, ...deleteAllExtraItems],
      footnote: "You'll start again from the Welcome screen.",
      confirmLabel: 'Delete all data',
    );
    if (!confirmed) return;
    await deleteAllData(ref);
    if (context.mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GroupCard(
      children: [
        AppListRow(
          icon: Icons.shield_outlined,
          title: 'Privacy and AI',
          subtitle: 'What is stored and how AI review will work',
          onTap: () => context.push(AppRoutes.privacy),
        ),
        AppListRow(
          key: const ValueKey('resetProgress'),
          icon: Icons.restart_alt_rounded,
          iconColor: AppColors.errorText,
          iconBackground: AppColors.errorTint,
          title: 'Reset progress',
          titleColor: AppColors.errorText,
          subtitle: 'Keeps your study plan and settings',
          onTap: () => _reset(context, ref),
        ),
        AppListRow(
          key: const ValueKey('deleteAllData'),
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.errorText,
          iconBackground: AppColors.errorTint,
          title: 'Delete all data',
          titleColor: AppColors.errorText,
          subtitle: 'Everything, including your plan',
          onTap: () => _deleteAll(context, ref),
        ),
      ],
    );
  }
}

class _About extends ConsumerWidget {
  const _About();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupCard(
          children: [
            AppListRow(
              key: const ValueKey('appVersion'),
              icon: Icons.info_outline_rounded,
              title: 'Version',
              trailing: Text(
                version ?? '…',
                style: AppTextStyles.tabular(AppTextStyles.labelLg),
              ),
            ),
            AppListRow(
              icon: Icons.article_outlined,
              title: 'Open-source licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Bandwise',
                applicationVersion: version,
              ),
            ),
            if (kDebugMode)
              AppListRow(
                key: const ValueKey('componentGallery'),
                icon: Icons.widgets_outlined,
                title: 'Component gallery',
                subtitle: 'Debug builds only',
                onTap: () => context.push(AppRoutes.componentGallery),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          disclaimerText,
          key: const ValueKey('disclaimer'),
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
