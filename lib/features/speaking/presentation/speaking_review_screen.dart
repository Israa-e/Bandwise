import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import '../domain/speaking_devices.dart';
import 'speaking_providers.dart';
import 'widgets/speaking_widgets.dart';

/// Self-review of a finished attempt: automatic checks, playback, and the
/// learner's own ticks against the four criteria. No AI, no estimate, no
/// band.
class SpeakingReviewScreen extends ConsumerWidget {
  const SpeakingReviewScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(speakingAttemptsProvider);
    final content = ref.watch(speakingContentProvider);
    void back() => context.go(AppRoutes.speakingHub);
    if ((attempts.hasError && !attempts.isLoading) ||
        (content.hasError && !content.isLoading)) {
      return SessionMessageScaffold(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load this session",
        message: 'Try again in a moment.',
        onBack: back,
        onRetry: () => ref
          ..invalidate(speakingAttemptsProvider)
          ..invalidate(speakingContentProvider),
      );
    }
    final list = attempts.value;
    final c = content.value;
    if (list == null || c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final attempt = list.where((a) => a.id == attemptId).firstOrNull;
    if (attempt == null) {
      return SessionMessageScaffold(
        icon: Icons.search_off_rounded,
        title: 'Session not found',
        message: 'It may have been deleted with your recordings.',
        onBack: back,
      );
    }
    return _Review(attempt: attempt, content: c);
  }
}

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.attempt, required this.content});

  final SpeakingAttempt attempt;
  final SpeakingContent content;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  late final SpeakingAudio _audio = ref.read(speakingAudioFactoryProvider)();
  StreamSubscription<bool>? _playing;
  String? _playingId;
  late final _ticks = <SpeakingCriterion, Set<int>>{
    for (final e in widget.attempt.selfAssessment.entries) e.key: {...e.value},
  };

  @override
  void initState() {
    super.initState();
    _playing = _audio.playingStream.listen((p) {
      if (!p && mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _playing?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _play(RecordedAnswer a) async {
    if (_playingId == a.questionId) {
      await _audio.pause();
      return;
    }
    final path = a.path;
    if (path == null) return;
    await _audio.loadRecording(path);
    setState(() => _playingId = a.questionId);
    await _audio.play();
  }

  Future<void> _tick(SpeakingCriterion c, int i, bool on) async {
    setState(() {
      final set = _ticks[c] ??= {};
      on ? set.add(i) : set.remove(i);
    });
    await ref
        .read(speakingAttemptRepositoryProvider)
        .saveAttempt(widget.attempt.copyWith(selfAssessment: _ticks));
    ref.invalidate(speakingAttemptsProvider);
  }

  String _questionText(RecordedAnswer a) {
    if (a.isLongTurn) {
      return widget.content.cueCard(a.questionId)?.prompt ?? 'Part 2 talk';
    }
    return widget.content.questions[a.questionId]?.text ?? 'Question';
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    final confidence = attempt.mode == SpeakingMode.confidence;
    return Scaffold(
      appBar: TitledSessionTopBar(
        title: 'Self-review',
        closeTooltip: 'Close',
        onClose: () => context.go(AppRoutes.speakingHub),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Semantics(
            header: true,
            child: const Text('Self-review', style: AppTextStyles.headlineLg),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${attempt.mode.label} · ${formatShortDate(attempt.finishedAt)} · '
            '${attempt.answers.length} '
            '${attempt.answers.length == 1 ? 'answer' : 'answers'}',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          const NoAiFeedbackBanner(),
          if (confidence) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confidence sessions are private and never scored.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _ChecksCard(attempt: attempt, questionText: _questionText),
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Your answers'),
          for (final a in attempt.answers) ...[
            _AnswerCard(
              answer: a,
              question: _questionText(a),
              playing: _playingId == a.questionId,
              onPlay: () => _play(a),
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
          if (attempt.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const SectionTitle('Your Part 2 notes'),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Text(attempt.notes, style: AppTextStyles.bodyMd),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Check yourself'),
          Text(
            'Listen to your answers, then tick what you think you did. Your '
            'ticks are saved for you and never turned into a score.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          for (final c in SpeakingCriterion.values) ...[
            AppCard(
              key: ValueKey('criterion-${c.name}'),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xs,
                AppSpacing.smd,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.smd,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(c.label, style: AppTextStyles.labelLg),
                    ),
                  ),
                  for (final (i, statement) in c.statements.indexed)
                    CheckboxListTile(
                      key: ValueKey('tick-${c.name}-$i'),
                      value: _ticks[c]?.contains(i) ?? false,
                      onChanged: (v) => _tick(c, i, v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      title: Text(statement, style: AppTextStyles.bodyMd),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: AppButton.primary(
          label: 'Back to Speaking',
          onPressed: () => context.go(AppRoutes.speakingHub),
        ),
      ),
    );
  }
}

/// Measured, not judged: speaking time against the usual range, long
/// pauses with where they start, and answers that were cut short.
class _ChecksCard extends StatelessWidget {
  const _ChecksCard({required this.attempt, required this.questionText});

  final SpeakingAttempt attempt;
  final String Function(RecordedAnswer) questionText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('automaticChecks'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Checked automatically',
              style: AppTextStyles.headlineSm,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Measured from your recordings: how long you spoke, pauses over '
            '3 seconds, and answers that were stopped.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          for (final (i, a) in attempt.answers.indexed) ...[
            const SizedBox(height: AppSpacing.smd),
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            if (i > 0) const SizedBox(height: AppSpacing.smd),
            _CheckRow(
              key: ValueKey('check-${a.questionId}'),
              answer: a,
              question: questionText(a),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({super.key, required this.answer, required this.question});

  final RecordedAnswer answer;
  final String question;

  @override
  Widget build(BuildContext context) {
    final check = AnswerCheck(answer);
    final fit = switch (check.fit) {
      LengthFit.usual => 'In the usual range',
      LengthFit.short => 'Shorter than usual',
      LengthFit.long => 'Longer than usual',
    };
    final muted = AppTextStyles.bodySm.copyWith(color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${answer.part.label} · $question',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMd,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatSpeakingTime(answer.duration),
                style: AppTextStyles.tabular(
                  AppTextStyles.labelLg,
                ).copyWith(color: AppColors.text),
              ),
              TextSpan(text: '  $fit · ${check.targetLabel}'),
            ],
          ),
          style: muted,
        ),
        if (check.longTurnUnderAMinute)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Text(
              'Under a minute. In the test you can keep going for up to 2 '
              'minutes: next time, try adding another detail or example.',
              style: muted,
            ),
          ),
        for (final s in answer.silences)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Text(
              'Long pause at ${formatSpeakingTime(s.start)} '
              '(${s.length.inSeconds} s)',
              style: muted,
            ),
          ),
        if (answer.cutShort case final reason?)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Text(reason.label, style: muted),
          ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.question,
    required this.playing,
    required this.onPlay,
  });

  final RecordedAnswer answer;
  final String question;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final transcript = answer.transcript;
    return AppCard(
      key: ValueKey('answer-${answer.questionId}'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            answer.part.label.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            question,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: answer.path == null
                ? Text(
                    'Recording deleted',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                : AppButton.outline(
                    key: ValueKey('play-${answer.questionId}'),
                    label: playing
                        ? 'Pause'
                        : 'Play · ${formatSpeakingTime(answer.duration)}',
                    leadingIcon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    compact: true,
                    expand: false,
                    onPressed: onPlay,
                  ),
          ),
          if (transcript != null) ...[
            const SizedBox(height: AppSpacing.smd),
            Text(
              TranscriptCopy.label,
              key: const ValueKey('transcriptLabel'),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(transcript, style: AppTextStyles.bodyMd),
          ],
        ],
      ),
    );
  }
}
