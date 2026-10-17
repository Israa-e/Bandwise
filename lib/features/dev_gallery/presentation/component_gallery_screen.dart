import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/data/mock_home_repository.dart';
import '../../home/presentation/home_providers.dart';

/// Debug-only screen showing every shared widget in every state.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Component gallery'),
          actions: [
            const Text('RTL', style: AppTextStyles.labelMd),
            Switch(
              value: _rtl,
              onChanged: (value) => setState(() => _rtl = value),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: const [
            _Section('Mock data', child: _MockDataSwitches()),
            _Section('Colors', child: _ColorsDemo()),
            _Section('Typography', child: _TypographyDemo()),
            _Section('Buttons', child: _ButtonsDemo()),
            _Section('Cards', child: _CardsDemo()),
            _Section('Selection card — single', child: _SingleSelectDemo()),
            _Section('Selection card — multi', child: _MultiSelectDemo()),
            _Section('Selection card — quiz', child: _QuizDemo()),
            _Section('Progress', child: _ProgressDemo()),
            _Section('Chips', child: _ChipsDemo()),
            _Section('Text fields', child: _TextFieldsDemo()),
            _Section('Top bars', child: _TopBarsDemo()),
            _Section('Bottom nav', child: _BottomNavDemo()),
            _Section('Info banners', child: _BannersDemo()),
            _Section('Skeleton', child: _SkeletonDemo()),
            _Section('Empty state', child: _EmptyStateDemo()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debug switches

class _MockDataSwitches extends ConsumerWidget {
  const _MockDataSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixture = ref.watch(homeFixtureProvider);
    return SwitchCard(
      title: 'Home: active user',
      subtitle: fixture == HomeFixture.activeUser
          ? 'Showing a learner with history. Turn off for a new user.'
          : 'Showing a new user on day 1. Turn on for a learner with history.',
      value: fixture == HomeFixture.activeUser,
      onChanged: (active) => ref
          .read(homeFixtureProvider.notifier)
          .select(active ? HomeFixture.activeUser : HomeFixture.newUser),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout helpers

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.smd),
          child,
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

/// Vertical list with standard gaps.
class _Stack extends StatelessWidget {
  const _Stack(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.smd),
          children[i],
        ],
      ],
    );
  }
}

/// Frames a full-width component (bars, navs) so its edges are visible.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.nestedRadius,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      // Top bars include a SafeArea; remove the gallery's own insets.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demos

class _ColorsDemo extends StatelessWidget {
  const _ColorsDemo();

  static const _swatches = <(String, Color)>[
    ('primary', AppColors.primary),
    ('accent', AppColors.accent),
    ('background', AppColors.background),
    ('card', AppColors.card),
    ('text', AppColors.text),
    ('textMuted', AppColors.textMuted),
    ('selected', AppColors.selectedSurface),
    ('track', AppColors.track),
    ('success', AppColors.success),
    ('successTint', AppColors.successTint),
    ('warning', AppColors.warning),
    ('warningTint', AppColors.warningTint),
    ('error', AppColors.error),
    ('errorText', AppColors.errorText),
    ('listening', AppColors.listening),
    ('listeningTint', AppColors.listeningTint),
    ('reading', AppColors.reading),
    ('readingTint', AppColors.readingTint),
    ('writing', AppColors.writing),
    ('writingTint', AppColors.writingTint),
    ('speaking', AppColors.speaking),
    ('speakingTint', AppColors.speakingTint),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.smd,
      children: [
        for (final (name, color) in _swatches)
          SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadii.nestedRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  name,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypographyDemo extends StatelessWidget {
  const _TypographyDemo();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Headline XL 28', style: AppTextStyles.headlineXl),
          const Text('Headline L 24', style: AppTextStyles.headlineLg),
          const Text('Headline M 20', style: AppTextStyles.headlineMd),
          const Text('Headline S 18', style: AppTextStyles.headlineSm),
          const Text(
            'Body L 16 — reading passages',
            style: AppTextStyles.bodyLg,
          ),
          const Text('Body M 14 — default body', style: AppTextStyles.bodyMd),
          const Text('Body S 13 — helper text', style: AppTextStyles.bodySm),
          const Text('Label L 14', style: AppTextStyles.labelLg),
          const Text('Label M 12', style: AppTextStyles.labelMd),
          const Text('LABEL S 11', style: AppTextStyles.labelSm),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tabular: 01:11:58  18:40  32/40',
            style: AppTextStyles.tabular(AppTextStyles.headlineSm),
          ),
          Text(
            'Proportional: 01:11:58  18:40  32/40',
            style: AppTextStyles.headlineSm.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    void tap() {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Primary'),
        _Stack([
          AppButton.primary(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: tap,
          ),
          const AppButton.primary(
            label: 'Continue (disabled)',
            onPressed: null,
          ),
          AppButton.primary(label: 'Saving', isLoading: true, onPressed: tap),
        ]),
        const _Caption('Secondary (lime)'),
        _Stack([
          AppButton.secondary(
            label: 'Claim reward',
            leadingIcon: Icons.bolt_rounded,
            onPressed: tap,
          ),
          const AppButton.secondary(label: 'Claim (disabled)', onPressed: null),
          AppButton.secondary(label: 'Claim', isLoading: true, onPressed: tap),
        ]),
        const _Caption('Ghost'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton.ghost(label: 'Skip for now', onPressed: tap),
            const AppButton.ghost(label: 'Disabled', onPressed: null),
            AppButton.ghost(label: 'Loading', isLoading: true, onPressed: tap),
          ],
        ),
        const _Caption('Compact (inside cards)'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton.primary(
              label: 'Resume',
              trailingIcon: Icons.arrow_forward_rounded,
              compact: true,
              expand: false,
              onPressed: tap,
            ),
            AppButton.secondary(
              label: 'Review',
              compact: true,
              expand: false,
              onPressed: tap,
            ),
          ],
        ),
      ],
    );
  }
}

class _CardsDemo extends StatelessWidget {
  const _CardsDemo();

  @override
  Widget build(BuildContext context) {
    return _Stack([
      const AppCard(
        child: Text(
          'Default card: white, radius 18, micro-border, soft shadow.',
          style: AppTextStyles.bodyMd,
        ),
      ),
      AppCard(
        onTap: () {},
        semanticLabel: 'Tappable card',
        child: const Row(
          children: [
            Expanded(
              child: Text('Tappable card', style: AppTextStyles.labelLg),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
      Row(
        children: [
          for (final skill in [Skill.listening, Skill.reading]) ...[
            if (skill != Skill.listening) const SizedBox(width: AppSpacing.smd),
            Expanded(
              child: AppCard(
                color: skill.tint,
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(skill.icon, color: skill.color),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${skill.label} (tinted)',
                      style: AppTextStyles.labelLg,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ]);
  }
}

class _SingleSelectDemo extends StatefulWidget {
  const _SingleSelectDemo();

  @override
  State<_SingleSelectDemo> createState() => _SingleSelectDemoState();
}

class _SingleSelectDemoState extends State<_SingleSelectDemo> {
  int _selected = 1;

  static const _options = [
    ('10 min', 'Casual'),
    ('20 min', 'Regular'),
    ('30 min', 'Serious'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Interactive'),
        _Stack([
          for (var i = 0; i < _options.length; i++)
            SelectionCard(
              title: _options[i].$2,
              subtitle: '${_options[i].$1} a day',
              leading: SelectionLeadingBox(
                text: _options[i].$1.split(' ').first,
                color: i == _selected ? AppColors.onPrimary : AppColors.primary,
                background: i == _selected
                    ? AppColors.primary
                    : AppColors.primaryTint,
              ),
              badge: i == 1
                  ? const AppPill(
                      label: 'Popular',
                      size: AppPillSize.small,
                      background: AppColors.accent,
                      foreground: AppColors.onAccent,
                    )
                  : null,
              state: i == _selected
                  ? SelectionCardState.selected
                  : SelectionCardState.idle,
              onTap: () => setState(() => _selected = i),
            ),
        ]),
        const _Caption('All states'),
        _Stack([
          for (final state in SelectionCardState.values)
            SelectionCard(
              title: _stateName(state),
              subtitle: 'Single-select row',
              state: state,
              onTap: () {},
            ),
        ]),
      ],
    );
  }
}

class _MultiSelectDemo extends StatefulWidget {
  const _MultiSelectDemo();

  @override
  State<_MultiSelectDemo> createState() => _MultiSelectDemoState();
}

class _MultiSelectDemoState extends State<_MultiSelectDemo> {
  final _selected = <Skill>{Skill.writing};

  static const _subtitles = {
    Skill.listening: 'Sections 1–4, note-taking',
    Skill.reading: 'Skimming, True/False/Not Given',
    Skill.writing: 'Task 1 charts & Task 2 essays',
    Skill.speaking: 'Fluency, cue cards',
  };

  Widget _tile(Skill skill) => SelectionCard(
    mode: SelectionMode.multi,
    layout: SelectionCardLayout.tile,
    title: skill.label,
    subtitle: _subtitles[skill],
    leading: SelectionLeadingBox(
      icon: skill.icon,
      color: skill.color,
      background: skill.tint,
      circle: true,
    ),
    state: _selected.contains(skill)
        ? SelectionCardState.selected
        : SelectionCardState.idle,
    onTap: () => setState(
      () => _selected.contains(skill)
          ? _selected.remove(skill)
          : _selected.add(skill),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Interactive tile grid'),
        // Rows of two equal-height tiles; tiles grow with their text.
        for (var row = 0; row < Skill.values.length; row += 2) ...[
          if (row > 0) const SizedBox(height: AppSpacing.smd),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final skill in Skill.values.skip(row).take(2)) ...[
                  if (skill != Skill.values[row])
                    const SizedBox(width: AppSpacing.smd),
                  Expanded(child: _tile(skill)),
                ],
              ],
            ),
          ),
        ],
        const _Caption('All states'),
        _Stack([
          for (final state in SelectionCardState.values)
            SelectionCard(
              mode: SelectionMode.multi,
              title: _stateName(state),
              subtitle: 'Multi-select row',
              state: state,
              onTap: () {},
            ),
        ]),
      ],
    );
  }
}

class _QuizDemo extends StatefulWidget {
  const _QuizDemo();

  @override
  State<_QuizDemo> createState() => _QuizDemoState();
}

class _QuizDemoState extends State<_QuizDemo> {
  static const _options = [
    'had finalised',
    'have finalised',
    'were finalising',
    'would finalise',
  ];
  static const _answer = 0;

  int? _picked;
  bool _checked = false;

  SelectionCardState _stateFor(int i) {
    if (!_checked) {
      return i == _picked
          ? SelectionCardState.selected
          : SelectionCardState.idle;
    }
    if (i == _answer) return SelectionCardState.correct;
    if (i == _picked) return SelectionCardState.incorrect;
    return SelectionCardState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    return _Stack([
      const AppCard(
        child: Text(
          'By the time the conference ended, the delegates ______ several '
          'key agreements.',
          style: AppTextStyles.bodyLg,
        ),
      ),
      for (var i = 0; i < _options.length; i++)
        SelectionCard(
          title: _options[i],
          leading: SelectionLeadingBox(text: String.fromCharCode(65 + i)),
          state: _stateFor(i),
          onTap: _checked ? null : () => setState(() => _picked = i),
        ),
      if (_checked)
        InfoBanner(
          type: _picked == _answer
              ? InfoBannerType.success
              : InfoBannerType.error,
          title: _picked == _answer ? 'Well done' : 'Not quite',
          message:
              'The past perfect is needed because the action was completed '
              'before another past event.',
        ),
      AppButton.primary(
        label: _checked ? 'Try again' : 'Check answer',
        onPressed: _picked == null
            ? null
            : () => setState(() {
                if (_checked) _picked = null;
                _checked = !_checked;
              }),
      ),
    ]);
  }
}

class _ProgressDemo extends StatelessWidget {
  const _ProgressDemo();

  @override
  Widget build(BuildContext context) {
    final ringLabel = AppTextStyles.tabular(AppTextStyles.labelLg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Segmented step progress'),
        const Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: [
            SegmentedStepProgress(current: 0, total: 6),
            SegmentedStepProgress(current: 3, total: 6),
            SegmentedStepProgress(current: 6, total: 6),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const SegmentedStepProgress(current: 2, total: 8, width: null),
        const _Caption('Linear'),
        const _Stack([
          AppLinearProgress(value: 0, semanticLabel: 'Empty'),
          AppLinearProgress(value: 0.375, semanticLabel: 'Question 3 of 8'),
          AppLinearProgress(value: 1, semanticLabel: 'Complete'),
          AppLinearProgress(
            value: 0.65,
            color: AppColors.accent,
            semanticLabel: 'Unit progress',
          ),
          AppLinearProgress(
            value: 0.8,
            color: AppColors.reading,
            trackColor: AppColors.readingTint,
            height: 6,
            semanticLabel: 'Reading accuracy',
          ),
        ]),
        const _Caption('Circular'),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppCircularProgress(value: 0, center: Text('0%', style: ringLabel)),
            AppCircularProgress(
              value: 0.75,
              semanticLabel: 'Daily goal',
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('15', style: ringLabel),
                  Text(
                    '/20m',
                    style: AppTextStyles.tabular(
                      AppTextStyles.labelSm,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const AppCircularProgress(
              value: 1,
              color: AppColors.success,
              center: Icon(Icons.check_rounded, color: AppColors.success),
            ),
            const AppCircularProgress(
              value: 0.4,
              size: 40,
              strokeWidth: 4,
              color: AppColors.speaking,
              trackColor: AppColors.speakingTint,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatelessWidget {
  const _ChipsDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Skill'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final skill in Skill.values) SkillChip(skill: skill)],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SkillChip(skill: Skill.listening, label: '88% accuracy'),
            SkillChip(
              skill: Skill.reading,
              label: 'Mastered',
              size: AppPillSize.small,
            ),
          ],
        ),
        const _Caption('Streak'),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StreakChip(days: 14),
            StreakChip(days: 1),
            StreakChip(days: 0, active: false),
          ],
        ),
        const _Caption('Pill'),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppPill(
              label: 'Popular',
              background: AppColors.accent,
              foreground: AppColors.onAccent,
            ),
            AppPill(
              label: 'Due today',
              icon: Icons.schedule_rounded,
              iconColor: AppColors.warning,
              background: AppColors.warningTint,
              foreground: AppColors.text,
            ),
          ],
        ),
      ],
    );
  }
}

class _TextFieldsDemo extends StatefulWidget {
  const _TextFieldsDemo();

  @override
  State<_TextFieldsDemo> createState() => _TextFieldsDemoState();
}

class _TextFieldsDemoState extends State<_TextFieldsDemo> {
  final _email = TextEditingController();
  final _invalidEmail = TextEditingController(text: 'alex.morgan@domain');
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    _invalidEmail.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() {
      _emailError = value.isEmpty || RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)
          ? null
          : 'Please enter a valid email address (e.g. name@example.com)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Stack([
      const AppTextField(
        label: 'Full name',
        hint: 'Alex Morgan',
        helperText: 'Normal',
        visualStateOverride: AppTextFieldVisualState.normal,
      ),
      const AppTextField(
        label: 'Full name',
        hint: 'Alex Morgan',
        helperText: 'Focused (forced for the gallery)',
        visualStateOverride: AppTextFieldVisualState.focused,
      ),
      AppTextField(
        label: 'Email address',
        controller: _invalidEmail,
        errorText: 'Please enter a valid email address (e.g. name@example.com)',
      ),
      const AppTextField(
        label: 'Email address',
        hint: 'name@example.com',
        helperText: 'Disabled',
        enabled: false,
      ),
      const AppTextField(
        label: 'Password',
        isPassword: true,
        helperText: 'At least 8 characters',
        prefixIcon: Icons.lock_outline_rounded,
      ),
      AppTextField(
        label: 'Email (live validation)',
        controller: _email,
        hint: 'name@example.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        errorText: _emailError,
        onChanged: _validate,
      ),
    ]);
  }
}

class _TopBarsDemo extends StatelessWidget {
  const _TopBarsDemo();

  @override
  Widget build(BuildContext context) {
    return _Stack([
      _Frame(
        child: OnboardingTopBar(
          step: 2,
          totalSteps: 6,
          onBack: () {},
          trailing: AppButton.ghost(
            label: 'Skip',
            compact: true,
            onPressed: () {},
          ),
        ),
      ),
      _Frame(child: OnboardingTopBar(step: 6, totalSteps: 6, onBack: () {})),
      const _Frame(
        child: OnboardingTopBar(step: 1, totalSteps: 6, showBack: false),
      ),
      _Frame(
        child: AuthTopBar(
          onBack: () {},
          trailing: AppButton.ghost(
            label: 'Log in',
            compact: true,
            onPressed: () {},
          ),
        ),
      ),
      _Frame(child: AuthTopBar(onBack: () {})),
    ]);
  }
}

class _BottomNavDemo extends StatefulWidget {
  const _BottomNavDemo();

  @override
  State<_BottomNavDemo> createState() => _BottomNavDemoState();
}

class _BottomNavDemoState extends State<_BottomNavDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BannersDemo extends StatelessWidget {
  const _BannersDemo();

  @override
  Widget build(BuildContext context) {
    return _Stack([
      const InfoBanner(
        message:
            'This helps us recommend a starting point. It is not an '
            'official level.',
      ),
      const InfoBanner(
        type: InfoBannerType.success,
        title: 'Saved',
        message: 'Your draft was saved.',
      ),
      const InfoBanner(
        type: InfoBannerType.warning,
        title: 'Practice estimate — not an official IELTS score',
        message: 'AI feedback can be wrong. Use it as a guide, not a result.',
      ),
      InfoBanner(
        type: InfoBannerType.error,
        title: 'Couldn’t load this lesson',
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () {},
      ),
    ]);
  }
}

class _SkeletonDemo extends StatelessWidget {
  const _SkeletonDemo();

  @override
  Widget build(BuildContext context) {
    return const _Stack([
      SkeletonBox(width: 160, height: 24),
      SkeletonBox(height: 16),
      SkeletonCard(height: 96),
    ]);
  }
}

class _EmptyStateDemo extends StatelessWidget {
  const _EmptyStateDemo();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: EmptyStateView(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved words yet',
        message: 'Words you save during lessons will appear here.',
        action: AppButton.primary(
          label: 'Start a lesson',
          expand: false,
          onPressed: () {},
        ),
      ),
    );
  }
}

String _stateName(SelectionCardState state) => switch (state) {
  SelectionCardState.idle => 'Idle',
  SelectionCardState.selected => 'Selected',
  SelectionCardState.correct => 'Correct',
  SelectionCardState.incorrect => 'Incorrect',
  SelectionCardState.disabled => 'Disabled',
};
