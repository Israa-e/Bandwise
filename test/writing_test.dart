import 'dart:convert';

import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/router/app_routes.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/writing/data/writing_content.dart';
import 'package:bandwise/features/writing/domain/writing.dart';
import 'package:bandwise/features/writing/domain/writing_feedback.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';
import 'package:bandwise/features/writing/presentation/revision_compare_screen.dart';
import 'package:bandwise/features/writing/presentation/widgets/feedback_widgets.dart';
import 'package:bandwise/features/writing/presentation/writing_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 15);

const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  placementSkipped: true,
);

/// The fake time the app reads. Tests move it forward.
late DateTime _now;
late ProviderContainer _container;

Future<void> _launch(
  WidgetTester tester, {
  Size size = const Size(390, 1000),
  bool rtl = false,
}) async {
  _now = DateTime(2026, 10, 15, 9);
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(_onboarding.toJson()),
  });
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _container = ProviderContainer(
    overrides: [
      todayProvider.overrideWithValue(_today),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(_container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) => Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  _container.read(routerProvider).push(location);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Pumps a few frames without waiting for animations to end (the
/// evaluating spinner never ends).
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _essayField = find.byKey(const ValueKey('essayField'));

/// Scrolls the editor's list until [finder] is built and visible.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final list = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(finder, 300, scrollable: list);
    } on StateError {
      await tester.scrollUntilVisible(finder, -300, scrollable: list);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _write(WidgetTester tester, String text) async {
  await _reveal(tester, _essayField);
  await tester.enterText(_essayField, text);
  await tester.pump();
}

Future<void> _useSample(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('useSampleEssay'));
  await _reveal(tester, button);
  await _tap(tester, button);
}

/// Submits from the editor, confirming the dialog, and stops on the
/// evaluating screen.
Future<void> _submit(WidgetTester tester) async {
  await _tap(tester, find.widgetWithText(AppButton, 'Submit'));
  await tester.tap(find.widgetWithText(TextButton, 'Submit'));
  await _frames(tester);
}

/// Waits out the mock review.
Future<void> _awaitFeedback(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('evaluating')), findsOneWidget);
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>> _savedDrafts() async {
  final raw = (await SharedPreferences.getInstance()).getString(
    'writing.drafts.v1',
  );
  return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
}

Future<List<WritingSubmission>> _savedSubmissions() async {
  final raw = (await SharedPreferences.getInstance()).getString(
    'writing.submissions.v1',
  );
  if (raw == null) return [];
  return [
    for (final s in jsonDecode(raw) as List)
      WritingSubmission.fromJson(s as Map<String, dynamic>),
  ];
}

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

/// Every piece of text on screen.
List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];

final _range = RegExp(r'\d\.\d–\d\.\d');

/// The feedback rules: no bands, projections, percentages, descriptor
/// labels or rewrite buttons.
void _expectFeedbackRules(WidgetTester tester) {
  final banned = RegExp(
    r'\bband\b|projected|fastest roi|accept|cohesion \+|\+\d+%|'
    r'competent|very good|expert',
    caseSensitive: false,
  );
  for (final text in _allText(tester)) {
    expect(banned.hasMatch(text), isFalse, reason: text);
  }
  for (final label in ['Good', 'Competent', 'Very good', 'Expert']) {
    expect(find.text(label), findsNothing);
  }
}

String _wordCountText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('wordCount')))
    .textSpan!
    .toPlainText();

Finder _semantics(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

/// Opens Task [task]'s editor and submits its sample essay, ending on the
/// feedback overview.
Future<void> _submitSample(
  WidgetTester tester,
  WritingTask task, {
  bool timed = false,
}) async {
  await _go(tester, AppRoutes.writingTask(task.id, timed: timed));
  await _useSample(tester);
  await _submit(tester);
  await _awaitFeedback(tester);
}

void main() {
  group('hub', () {
    testWidgets('Practice tab opens the Writing hub', (tester) async {
      await _launch(tester);
      await _go(tester, AppRoutes.practice);
      final card = find.byKey(const ValueKey('practice-writing'));
      expect(
        find.descendant(of: card, matching: find.text('Coming soon')),
        findsNothing,
      );
      await _tap(tester, card);
      expect(find.text('Writing'), findsWidgets);
      expect(find.text('20 min · 150+ words'), findsOneWidget);
      expect(find.text('40 min · 250+ words'), findsOneWidget);
      expect(find.text(cyclingTask.topic), findsOneWidget);
      expect(find.text(universitiesTask.topic), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Timed'), findsOneWidget);
      expect(find.textContaining('No essays yet'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Start writing'), findsOneWidget);
    });

    testWidgets('Start writing opens the selected task and mode', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingHub);
      await _tap(
        tester,
        find.byKey(ValueKey('writingTask-${universitiesTask.id}')),
      );
      await _tap(tester, find.text('Timed'));
      await _tap(tester, find.widgetWithText(AppButton, 'Start writing'));
      expect(find.text('Task 2 · ${universitiesTask.topic}'), findsOneWidget);
      expect(find.byKey(const ValueKey('timer')), findsOneWidget);
      expect(find.text('40:00'), findsOneWidget);
    });
  });

  group('editor', () {
    testWidgets('learning mode: task card, tips, plan notes and live word '
        'count', (tester) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      expect(find.byKey(const ValueKey('taskCard')), findsOneWidget);
      expect(find.text(cyclingTask.prompt), findsOneWidget);
      expect(find.byKey(const ValueKey('tipsPanel')), findsOneWidget);
      expect(
        find.text(structureTips[WritingTaskType.task1]!.first),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('timer')), findsNothing);

      // The task card collapses and shows the chart on demand.
      await _tap(tester, find.byKey(const ValueKey('taskCardToggle')));
      expect(find.text(cyclingTask.instructions), findsNothing);
      await _tap(tester, find.text('View chart'));
      expect(find.text(cyclingChart.title), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('chartViewToggle')));
      expect(find.byKey(const ValueKey('chartTable')), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
      expect(find.text('View as chart'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Plan notes aren't counted.
      await _tap(tester, find.text('Plan your essay'));
      await tester.enterText(
        find.byKey(const ValueKey('planField')),
        'Belmont down, Arden up, Corvale jump',
      );
      await tester.pump();
      expect(_wordCountText(tester), startsWith('0 words'));

      await _write(tester, 'The line graph shows three cities.');
      expect(_wordCountText(tester), '6 words · 150 minimum');
      expect(_semantics('6 words, minimum 150'), findsOneWidget);
      await _useSample(tester);
      final words = countWords(cyclingTask.sampleEssay);
      expect(_wordCountText(tester), '$words words · 150 minimum');
      expect(_semantics('$words words, minimum 150, reached'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('autosaves every few seconds and on background', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      await _write(tester, 'First words');
      expect(find.text('Saving…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Draft saved'), findsOneWidget);
      var draft = (await _savedDrafts())['task:${cyclingTask.id}'];
      expect(draft['text'], 'First words');

      await _write(tester, 'First words and more');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      draft = (await _savedDrafts())['task:${cyclingTask.id}'];
      expect(draft['text'], 'First words and more');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    });

    testWidgets('leaving keeps the draft; the hub offers Continue draft', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingHub);
      await _tap(tester, find.widgetWithText(AppButton, 'Start writing'));
      await _write(tester, 'Cycling to work became more popular.');
      await _tap(tester, find.byTooltip('Close editor'));

      expect(find.byKey(const ValueKey('draftNotice')), findsOneWidget);
      expect(find.textContaining('6 words · Learning'), findsOneWidget);
      await _tap(tester, find.widgetWithText(AppButton, 'Continue draft'));
      await _reveal(tester, _essayField);
      expect(
        tester.widget<TextField>(_essayField).controller!.text,
        'Cycling to work became more popular.',
      );
      await _tap(tester, find.byTooltip('Close editor'));

      // Start over deletes the draft after confirming.
      await _tap(tester, find.widgetWithText(AppButton, 'Start over'));
      await _tap(tester, find.widgetWithText(TextButton, 'Delete draft'));
      await _reveal(tester, _essayField);
      expect(tester.widget<TextField>(_essayField).controller!.text, isEmpty);
    });

    testWidgets('an empty learning draft is not kept', (tester) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingHub);
      await _tap(tester, find.widgetWithText(AppButton, 'Start writing'));
      await _tap(tester, find.byTooltip('Close editor'));
      expect(find.widgetWithText(AppButton, 'Start writing'), findsOneWidget);
      expect(await _savedDrafts(), isEmpty);
    });

    testWidgets('timed mode: no tips, no spell check or autocorrect', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: true));
      expect(find.text('20:00'), findsOneWidget);
      expect(find.byKey(const ValueKey('tipsPanel')), findsNothing);
      expect(find.byKey(const ValueKey('planPanel')), findsNothing);
      expect(find.byType(AppBottomNav), findsNothing);
      final field = tester.widget<TextField>(_essayField);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.spellCheckConfiguration?.spellCheckEnabled, isFalse);
      expect(field.smartQuotesType, SmartQuotesType.disabled);

      _now = _now.add(const Duration(minutes: 15, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('04:30'), findsOneWidget);
      expect(find.textContaining('About 5 minutes left'), findsOneWidget);
    });

    testWidgets("timed mode: at 0:00, Time's up and auto-submit", (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: true));
      await _write(tester, 'Belmont fell while Arden rose.');
      _now = _now.add(const Duration(minutes: 20));
      await tester.pump(const Duration(seconds: 1));
      await _frames(tester);
      expect(find.text("Time's up"), findsOneWidget);
      await _awaitFeedback(tester);
      expect(find.text("Time's up"), findsOneWidget);
      final saved = (await _savedSubmissions()).single;
      expect(saved.timeUp, isTrue);
      expect(saved.timeUsed, const Duration(minutes: 20));
      expect(saved.text, 'Belmont fell while Arden rose.');
      expect(await _savedDrafts(), isEmpty);
    });

    testWidgets('timed mode: the timer survives background, and a draft '
        'reopened after the time is submitted', (tester) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingHub);
      await _tap(tester, find.text('Timed'));
      await _tap(tester, find.widgetWithText(AppButton, 'Start writing'));
      await _write(tester, 'Overall, cycling grew in two cities.');
      _now = _now.add(const Duration(minutes: 3));
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      _now = _now.add(const Duration(minutes: 4));
      for (final s in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(find.text('13:00'), findsOneWidget);

      // Leave; the timer keeps running from the start time.
      await _tap(tester, find.byTooltip('Close editor'));
      expect(find.textContaining('Timed'), findsWidgets);
      _now = _now.add(const Duration(minutes: 30));
      // Not settling: the review starts straight away.
      await tester.tap(find.widgetWithText(AppButton, 'Continue draft'));
      await _frames(tester);
      expect(find.text("Time's up"), findsOneWidget);
      await _awaitFeedback(tester);
      final saved = (await _savedSubmissions()).single;
      expect(saved.timeUsed, const Duration(minutes: 20));
      expect(saved.text, 'Overall, cycling grew in two cities.');
    });

    testWidgets('submit dialog warns under the minimum but allows it', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      _now = _now.add(const Duration(minutes: 2, seconds: 5));
      await _write(tester, 'Too short to count.');
      await _tap(tester, find.widgetWithText(AppButton, 'Submit'));
      expect(find.text('Submit your essay?'), findsOneWidget);
      expect(
        find.text('Responses under 150 words are penalised.'),
        findsOneWidget,
      );
      expect(find.text("You can't edit after submitting."), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('02:05'), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Keep writing'));

      await _useSample(tester);
      await _tap(tester, find.widgetWithText(AppButton, 'Submit'));
      expect(find.byKey(const ValueKey('underMinimum')), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Submit'));
      await _frames(tester);
      expect(find.text('Reviewing your essay'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await _awaitFeedback(tester);
    });

    testWidgets('submitting records minutes and a streak day; Home shows '
        'the essay', (tester) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      _now = _now.add(const Duration(minutes: 12));
      await _write(tester, 'A short essay.');
      await _submit(tester);
      await _awaitFeedback(tester);
      final progress = await _savedProgress();
      expect(progress.minutesOn(_today), 12);
      expect(progress.streak(_today), 1);
      await _tap(tester, find.byTooltip('Close feedback'));
      expect(find.text('Feedback ready'), findsNothing);
      expect(find.text('Demo feedback'), findsOneWidget);
      _container.read(routerProvider).go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 essay this week'), findsOneWidget);
    });
  });

  group('feedback', () {
    testWidgets('Task 1 sample: ranges with the estimate label, Task '
        'Achievement', (tester) async {
      await _launch(tester);
      await _submitSample(tester, cyclingTask);
      expect(
        find.byKey(const ValueKey('feedbackOverview-task1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('sampleNotice')), findsOneWidget);
      expect(find.byKey(const ValueKey('demoBanner')), findsNothing);
      expect(find.text(estimateLabel), findsWidgets);
      expect(find.text('6.0–6.5'), findsWidgets);
      expect(find.text('View chart'), findsOneWidget);
      await _reveal(tester, find.text('Task Achievement'));
      expect(find.text('Task Response'), findsNothing);
      for (final c in WritingTaskType.task1.criteria) {
        await _reveal(tester, find.byKey(ValueKey('criterion-${c.id}')));
      }
      // Every range on screen is labelled for screen readers.
      final rangeLabels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .whereType<String>()
          .where((l) => RegExp(r'\d\.\d to \d\.\d').hasMatch(l));
      expect(rangeLabels, isNotEmpty);
      for (final l in rangeLabels) {
        expect(l, contains(estimateLabel));
      }
      _expectFeedbackRules(tester);
      await tester.drag(
        find.byKey(const ValueKey('feedbackOverview-task1')),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paragraph 4'), findsOneWidget);
      _expectFeedbackRules(tester);

      final saved = (await _savedSubmissions()).single;
      expect(saved.result, isA<AnalysedResult>());
    });

    testWidgets('Task 2 sample: Task Response', (tester) async {
      await _launch(tester);
      await _submitSample(tester, universitiesTask);
      expect(
        find.byKey(const ValueKey('feedbackOverview-task2')),
        findsOneWidget,
      );
      expect(find.text('View chart'), findsNothing);
      await _reveal(tester, find.text('Task Response'));
      expect(find.text('Task Achievement'), findsNothing);
      _expectFeedbackRules(tester);
    });

    testWidgets('own text: demo feedback only, no ranges or notes', (
      tester,
    ) async {
      await _launch(tester);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      await _useSample(tester);
      // One change and it's no longer the sample.
      final edited = cyclingTask.sampleEssay.replaceFirst(
        'who cycling',
        'who cycled',
      );
      await _write(tester, edited);
      await _submit(tester);
      await _awaitFeedback(tester);
      expect(find.byKey(const ValueKey('demoBanner')), findsOneWidget);
      expect(
        find.text("Demo feedback — AI review isn't connected yet"),
        findsOneWidget,
      );
      expect(find.text(estimateLabel), findsNothing);
      for (final t in _allText(tester)) {
        expect(_range.hasMatch(t), isFalse, reason: t);
      }
      await _reveal(tester, find.text('Task Achievement'));
      expect(find.byKey(const ValueKey('annotationsCard')), findsNothing);
      _expectFeedbackRules(tester);
    });

    testWidgets('error state keeps the essay; Retry gets feedback', (
      tester,
    ) async {
      await _launch(tester);
      _container.read(writingDebugProvider.notifier).setSimulateError(true);
      await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
      await _useSample(tester);
      await _submit(tester);
      await _awaitFeedback(tester);
      expect(find.text("Feedback isn't available right now"), findsOneWidget);
      expect(find.text('Your essay is saved.'), findsOneWidget);
      final saved = (await _savedSubmissions()).single;
      expect(saved.result, isNull);
      expect(
        normalizeEssay(saved.text),
        normalizeEssay(cyclingTask.sampleEssay),
      );

      _container.read(writingDebugProvider.notifier).setSimulateError(false);
      await tester.tap(find.widgetWithText(AppButton, 'Retry'));
      await _frames(tester);
      await _awaitFeedback(tester);
      expect(find.byKey(const ValueKey('overallCard')), findsOneWidget);
      expect((await _savedSubmissions()).single.result, isA<AnalysedResult>());
    });

    testWidgets('saved feedback reopens from the hub without a new review', (
      tester,
    ) async {
      await _launch(tester);
      await _submitSample(tester, cyclingTask);
      await _tap(tester, find.byTooltip('Close feedback'));
      expect(find.text('Feedback ready'), findsOneWidget);
      await _tap(tester, find.text('Feedback ready'));
      expect(find.byKey(const ValueKey('evaluating')), findsNothing);
      expect(find.byKey(const ValueKey('overallCard')), findsOneWidget);
    });

    testWidgets('criterion detail: range, label, strengths and examples', (
      tester,
    ) async {
      await _launch(tester);
      await _submitSample(tester, cyclingTask);
      await _tap(
        tester,
        find.byKey(const ValueKey('criterion-grammaticalRange')),
      );
      expect(find.text('Grammatical Range and Accuracy'), findsOneWidget);
      expect(find.text('5.5–6.0'), findsOneWidget);
      expect(find.text(estimateLabel), findsOneWidget);
      expect(find.text('What you did well'), findsOneWidget);
      expect(find.text('What to improve'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('example-t1-g1')));
      expect(find.byKey(const ValueKey('note-t1-g1')), findsOneWidget);
      expect(find.text('who cycled'), findsOneWidget);
      _expectFeedbackRules(tester);
    });

    testWidgets('annotated essay: stats, filters, distinct highlights and '
        'the note sheet', (tester) async {
      await _launch(tester);
      await _submitSample(tester, cyclingTask);
      await _tap(tester, find.byKey(const ValueKey('annotationsCard')));

      final notes = sampleFeedback[cyclingTask.id]!.notes;
      for (final type in AnnotationType.values) {
        final n = notes.where((x) => x.type == type).length;
        expect(
          _semantics('${type.label}: $n ${n == 1 ? 'note' : 'notes'}'),
          findsOneWidget,
          reason: type.name,
        );
      }

      List<TextSpan> highlights() {
        final spans = <TextSpan>[];
        for (final rt in tester.widgetList<RichText>(
          find.descendant(
            of: find.byKey(const ValueKey('annotatedEssay')),
            matching: find.byType(RichText),
          ),
        )) {
          rt.text.visitChildren((s) {
            if (s is TextSpan && s.recognizer != null) spans.add(s);
            return true;
          });
        }
        return spans;
      }

      expect(highlights(), hasLength(notes.length));
      // Each type has its own underline style, plus an icon.
      final styles = {for (final s in highlights()) s.style!.decorationStyle};
      expect(styles, hasLength(AnnotationType.values.length));
      for (final type in AnnotationType.values) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('annotatedEssay')),
            matching: find.byIcon(type.icon),
          ),
          findsWidgets,
        );
      }

      await _tap(tester, find.byKey(const ValueKey('filter-grammar')));
      final grammar = notes.where((x) => x.type == AnnotationType.grammar);
      expect(highlights(), hasLength(grammar.length));
      expect(highlights().map((s) => s.text), grammar.map((n) => n.original));

      // Open the first grammar note, then Next, then Got it.
      (highlights().first.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('note-t1-g1')), findsOneWidget);
      expect(find.text('Suggested alternative'), findsOneWidget);
      expect(find.text('1 of ${grammar.length}'), findsOneWidget);
      expect(find.textContaining('Accept'), findsNothing);
      await _tap(tester, find.widgetWithText(AppButton, 'Next'));
      expect(find.byKey(const ValueKey('note-t1-g2')), findsOneWidget);
      await _tap(tester, find.widgetWithText(AppButton, 'Got it'));
      expect(find.byKey(const ValueKey('note-t1-g2')), findsNothing);
      _expectFeedbackRules(tester);
    });

    testWidgets('revise and resubmit, then compare drafts', (tester) async {
      await _launch(tester);
      await _submitSample(tester, cyclingTask);
      await _tap(tester, find.widgetWithText(AppButton, 'Revise and resubmit'));
      expect(find.text('Revise · Task 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('notesToAddress')), findsOneWidget);
      expect(find.text('‘who cycling’'), findsOneWidget);
      await _reveal(tester, _essayField);
      final field = tester.widget<TextField>(_essayField);
      expect(
        normalizeEssay(field.controller!.text),
        normalizeEssay(cyclingTask.sampleEssay),
      );

      final revised = field.controller!.text
          .replaceFirst('who cycling', 'who cycled')
          .replaceFirst('the biggest proportion', 'the largest proportion');
      await _write(tester, revised);
      await _submit(tester);
      await _awaitFeedback(tester);
      // A revision isn't the sample, so it gets demo feedback.
      expect(find.byKey(const ValueKey('demoBanner')), findsOneWidget);

      await _tap(tester, find.widgetWithText(AppButton, 'Compare drafts'));
      expect(find.text(RevisionCompareScreen.note), findsOneWidget);
      Finder count(String key, String value) => find.descendant(
        of: find.byKey(ValueKey('count-$key')),
        matching: find.text(value),
      );
      expect(count('replaced', '2'), findsOneWidget);
      expect(count('added', '0'), findsOneWidget);
      expect(count('removed', '0'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('diff-0')),
          matching: find.text('1 replaced'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('diff-1')),
          matching: find.text('No changes'),
        ),
        findsOneWidget,
      );
      for (final t in _allText(tester)) {
        expect(_range.hasMatch(t), isFalse, reason: t);
      }
      _expectFeedbackRules(tester);

      final saved = await _savedSubmissions();
      expect(saved, hasLength(2));
      expect(saved.last.revisionOf, saved.first.id);
    });
  });

  group('layout', () {
    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';
      testWidgets('every writing screen at 320px: no overflow ($dir)', (
        tester,
      ) async {
        await _launch(tester, size: const Size(320, 640), rtl: rtl);
        Future<void> scroll() async {
          for (var i = 0; i < 8; i++) {
            expect(tester.takeException(), isNull);
            final lists = find.byType(Scrollable);
            if (lists.evaluate().isEmpty) return;
            await tester.drag(lists.first, const Offset(0, -400));
            await tester.pumpAndSettle();
          }
        }

        await _go(tester, AppRoutes.writingHub);
        await scroll();
        await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: true));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.byTooltip('Close editor'));
        await _go(tester, AppRoutes.writingTask(cyclingTask.id, timed: false));
        await _tap(tester, find.byKey(const ValueKey('taskCardToggle')));
        await _tap(tester, find.byKey(const ValueKey('taskCardToggle')));
        await _tap(tester, find.text('View chart'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.byKey(const ValueKey('chartViewToggle')));
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await _useSample(tester);
        await _submit(tester);
        expect(tester.takeException(), isNull);
        await _awaitFeedback(tester);
        await scroll();
        await _tap(tester, find.byKey(const ValueKey('annotationsCard')));
        await scroll();
        _container.read(routerProvider).pop();
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.byKey(const ValueKey('criterion-coherenceCohesion')),
        );
        await scroll();
        _container.read(routerProvider).pop();
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.widgetWithText(AppButton, 'Revise and resubmit'),
        );
        await scroll();
        await _write(tester, 'A short revision.');
        await _submit(tester);
        await _awaitFeedback(tester);
        await scroll();
        await _tap(tester, find.widgetWithText(AppButton, 'Compare drafts'));
        await scroll();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tablet: the revise editor puts notes beside the text', (
      tester,
    ) async {
      await _launch(tester, size: const Size(1024, 768));
      await _submitSample(tester, universitiesTask);
      await _tap(tester, find.widgetWithText(AppButton, 'Revise and resubmit'));
      await _reveal(tester, _essayField);
      final notes = tester.getRect(
        find.byKey(const ValueKey('notesToAddress')),
      );
      final editor = tester.getRect(_essayField);
      expect(notes.right, lessThanOrEqualTo(editor.left));
      expect(tester.takeException(), isNull);
    });
  });
}
