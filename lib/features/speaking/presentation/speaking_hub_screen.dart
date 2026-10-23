import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import 'speaking_providers.dart';
import 'widgets/speaking_widgets.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// After this many Confidence sessions, the hub suggests a Timed test.
const confidenceSessionsBeforeTimed = 3;

/// Speaking hub: pick a mode and, for Practice and Confidence, a part and
/// a topic; the automatic transcript is off unless turned on.
class SpeakingHubScreen extends ConsumerStatefulWidget {
  const SpeakingHubScreen({super.key});

  @override
  ConsumerState<SpeakingHubScreen> createState() => _SpeakingHubScreenState();
}

class _SpeakingHubScreenState extends ConsumerState<SpeakingHubScreen> {
  var _mode = SpeakingMode.practice;
  var _part = SpeakingPart.part1;
  String? _setId;
  var _transcript = false;

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(speakingContentProvider);
    final Widget body;
    Widget? bottom;
    if (content.hasValue && !content.hasError) {
      final c = content.requireValue;
      final sets = _setsFor(c);
      final setId = sets.any((s) => s.id == _setId) ? _setId : sets.first.id;
      body = _content(c, sets, setId!);
      bottom = StickyActionBar(
        child: AppButton.primary(
          key: const ValueKey('startSpeaking'),
          label: _mode == SpeakingMode.timed ? 'Start the test' : 'Start',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () => context.push(
            _mode == SpeakingMode.timed
                ? AppRoutes.speakingTest(transcript: _transcript)
                : AppRoutes.speakingPractice(
                    mode: _mode.name,
                    part: _part.index + 1,
                    setId: setId,
                    transcript: _transcript,
                  ),
          ),
        ),
      );
    } else if (content.hasError && !content.isLoading) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load speaking practice",
            message: 'Try again in a moment.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(speakingContentProvider),
          ),
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: const TabTopBar(title: 'Speaking', showBack: true),
      body: body,
      bottomNavigationBar: bottom,
    );
  }

  /// The topics (Part 1) or cue cards (Parts 2 and 3) to choose from.
  List<({String id, String title, String subtitle})> _setsFor(
    SpeakingContent c,
  ) => switch (_part) {
    SpeakingPart.part1 => [
      for (final t in c.part1)
        (id: t.id, title: t.title, subtitle: '${t.questions.length} questions'),
    ],
    SpeakingPart.part2 => [
      for (final card in c.cueCards)
        (
          id: card.id,
          title: card.title,
          subtitle: 'Cue card and a follow-up question',
        ),
    ],
    SpeakingPart.part3 => [
      for (final card in c.cueCards)
        (
          id: card.id,
          title: card.part3Title,
          subtitle: '${card.part3Questions.length} discussion questions',
        ),
    ],
  };

  Widget _content(
    SpeakingContent c,
    List<({String id, String title, String subtitle})> sets,
    String setId,
  ) {
    final progress = ref.watch(progressControllerProvider).value;
    final sessions = progress?.speakingSessions ?? const <SpeakingSession>[];
    final confidenceDone = sessions
        .where((s) => s.mode == SpeakingSession.confidenceMode)
        .length;
    final timedDone = sessions
        .where((s) => s.mode == SpeakingSession.timedMode)
        .length;
    return ListView(
      padding: _padding,
      children: [
        const SectionTitle('Mode'),
        _modeCard(
          SpeakingMode.practice,
          'One question at a time. Record, listen back and try again, with '
          'no time pressure.',
          Icons.mic_none_rounded,
        ),
        const SizedBox(height: AppSpacing.smd),
        _modeCard(
          SpeakingMode.confidence,
          'A calm space: no timers, gentle prompts to organise your ideas, '
          'and nothing is scored.',
          Icons.self_improvement_rounded,
        ),
        const SizedBox(height: AppSpacing.smd),
        _modeCard(
          SpeakingMode.timed,
          'The real format, about 11–14 minutes. Questions are spoken once '
          'and recording starts after each one.',
          Icons.timer_outlined,
        ),
        if (confidenceDone >= confidenceSessionsBeforeTimed &&
            timedDone == 0 &&
            _mode != SpeakingMode.timed) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            key: const ValueKey('tryTimed'),
            type: InfoBannerType.success,
            title: 'Ready for a Timed test?',
            message:
                "You've done $confidenceDone Confidence sessions. When you "
                'feel ready, try the real format.',
            actionLabel: 'Try a Timed test',
            onAction: () => setState(() => _mode = SpeakingMode.timed),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_mode == SpeakingMode.timed)
          const _TimedOutline()
        else ...[
          const SectionTitle('Part'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in SpeakingPart.values)
                AppFilterChip(
                  key: ValueKey('part-${p.name}'),
                  label: p.label,
                  selected: p == _part,
                  onTap: () => setState(() {
                    _part = p;
                    _setId = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _part.description,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          for (final s in sets) ...[
            SelectionCard(
              key: ValueKey('set-${s.id}'),
              title: s.title,
              subtitle: s.subtitle,
              leading: const SelectionLeadingBox(
                icon: Icons.record_voice_over_outlined,
              ),
              state: s.id == setId
                  ? SelectionCardState.selected
                  : SelectionCardState.idle,
              onTap: () => setState(() => _setId = s.id),
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        SwitchCard(
          key: const ValueKey('transcriptSwitch'),
          title: 'Automatic transcript',
          subtitle:
              'Off by default. ${TranscriptCopy.label}. '
              '${TranscriptCopy.deviceNote}',
          value: _transcript,
          onChanged: (v) => setState(() => _transcript = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Recent sessions'),
        const _RecentSessions(),
      ],
    );
  }

  Widget _modeCard(SpeakingMode mode, String subtitle, IconData icon) =>
      SelectionCard(
        key: ValueKey('mode-${mode.name}'),
        title: mode.label,
        subtitle: subtitle,
        leading: SelectionLeadingBox(icon: icon),
        state: _mode == mode
            ? SelectionCardState.selected
            : SelectionCardState.idle,
        onTap: () => setState(() => _mode = mode),
      );
}

class _TimedOutline extends StatelessWidget {
  const _TimedOutline();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Part 1', '4–5 minutes of questions about yourself.'),
      (
        'Part 2',
        '1 minute to prepare with notes, then talk for up to 2 minutes.',
      ),
      ('Part 3', '4–5 minutes of discussion on the same theme.'),
    ];
    return AppCard(
      key: const ValueKey('timedOutline'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (part, text) in steps)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: Text.rich(
                TextSpan(
                  text: '$part  ',
                  style: AppTextStyles.labelLg,
                  children: [TextSpan(text: text, style: AppTextStyles.bodyMd)],
                ),
              ),
            ),
          Text(
            "Each question is spoken once. If you didn't catch it, you can "
            'ask for it again once, as in the real test. No hints.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// The latest sessions kept on this device, newest first, each opening
/// its self-review.
class _RecentSessions extends ConsumerWidget {
  const _RecentSessions();

  static const _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(speakingAttemptsProvider).value ?? const [];
    if (attempts.isEmpty) {
      return Text(
        'No sessions yet. Your recordings stay on this device.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
      );
    }
    final today = ref.watch(todayProvider);
    return Column(
      children: [
        for (final (i, a) in attempts.reversed.take(_shown).indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AppCard(
            key: ValueKey('session-${a.id}'),
            onTap: () => context.push(AppRoutes.speakingReview(a.id)),
            padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
            semanticLabel:
                '${a.mode.label}, ${timeAgoLabel(today, a.finishedAt)}, '
                '${a.answers.length} answers. Open self-review',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.mode.label, style: AppTextStyles.labelLg),
                        const SizedBox(height: 2),
                        Text(
                          '${timeAgoLabel(today, a.finishedAt)} · '
                          '${a.answers.length} '
                          '${a.answers.length == 1 ? 'answer' : 'answers'}'
                          '${a.mode == SpeakingMode.confidence ? '' : ' · ${formatSpeakingTime(a.speakingTime)} speaking'}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
