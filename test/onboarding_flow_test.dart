import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/data/mock_home_repository.dart';
import 'package:bandwise/features/home/presentation/home_providers.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/onboarding/data/mock_placement_repository.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed "today" so calendar taps and week counts are deterministic.
final _today = DateTime(2026, 10, 13);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // A new ProviderScope is a fresh app start; prefs survive it.
        key: UniqueKey(),
        overrides: [
          todayProvider.overrideWithValue(_today),
          // Home loads without a delay, so no timer outlives the test.
          homeRepositoryProvider.overrideWithValue(
            MockHomeRepository(
              fixture: HomeFixture.newUser,
              today: _today,
              delay: Duration.zero,
            ),
          ),
        ],
        child: const BandwiseApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // splash
    await tester.pumpAndSettle();
  }

  Future<OnboardingState> saved() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      'onboarding.v1',
    );
    return OnboardingState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
  }

  AppButton bottomButton(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  Future<void> tapText(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      // Lazily built list item: scroll until it exists.
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('guest completes the whole flow and lands on Home', (
    tester,
  ) async {
    await launch(tester);

    // Welcome
    expect(find.textContaining('(6.0 – 8.0+)'), findsOneWidget);
    await tapText(tester, 'Continue as guest');

    // Step 1: target band — no Skip, Continue disabled until a choice.
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(bottomButton(tester, 'Continue').onPressed, isNull);
    await tapText(tester, 'Good user');
    expect(bottomButton(tester, 'Continue').onPressed, isNotNull);
    await tapText(tester, 'Continue');

    // Step 2: exam date
    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(bottomButton(tester, 'Continue').onPressed, isNull);
    await tapText(tester, '12'); // past day: disabled
    expect(bottomButton(tester, 'Continue').onPressed, isNull);
    await tapText(tester, '30');
    expect(find.text('2 weeks to prepare'), findsOneWidget);
    expect(find.textContaining('Band'), findsNothing);
    await tapText(tester, "I haven't booked my exam yet");
    expect(find.text('2 weeks to prepare'), findsNothing);
    await tapText(tester, "I haven't booked my exam yet");
    expect(find.text('2 weeks to prepare'), findsOneWidget);
    await tapText(tester, 'Continue');

    // Step 3: current level — Skip stores null.
    expect(find.text('Step 3 of 6'), findsOneWidget);
    expect(bottomButton(tester, 'Continue').onPressed, isNull);
    await tapText(tester, 'Skip');
    expect((await saved()).level, isNull);

    // Step 4: daily time — valid by default (20).
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(bottomButton(tester, 'Continue').onPressed, isNotNull);
    await tapText(tester, 'Daily study reminder');
    expect(find.text('7:30 PM'), findsOneWidget);
    await tapText(tester, 'Change time');
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tapText(tester, 'OK');
    await tapText(tester, 'Continue');

    // Step 5: skills
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(bottomButton(tester, 'Continue').onPressed, isNull);
    await tapText(tester, 'Writing');
    await tapText(tester, 'Continue');

    // Step 6: placement — 8 questions, always pick option A.
    expect(find.text('Step 6 of 6'), findsOneWidget);
    for (var q = 1; q <= 8; q++) {
      expect(find.text('Question $q of 8'), findsOneWidget);
      expect(bottomButton(tester, 'Check answer').onPressed, isNull);
      await tapText(tester, 'A');
      await tapText(tester, 'Check answer');
      await tapText(tester, q < 8 ? 'Next question' : 'See my plan');
    }

    // Plan reads from the controller.
    expect(find.text('Your study plan is ready'), findsOneWidget);
    expect(find.text('Good user'), findsOneWidget);
    expect(find.text('Oct 30, 2026'), findsOneWidget);
    expect(find.text('2 weeks left'), findsOneWidget);
    expect(find.text('20 min / day'), findsOneWidget);
    expect(find.text('7:30 PM reminder'), findsOneWidget);
    expect(find.text('Writing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('7 days / week'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('7 days / week'), findsOneWidget);
    expect(find.text('20m'), findsNWidgets(7));
    // Option A is right for 1 of the 8 mock questions.
    expect(find.textContaining('1 of 8 correct'), findsOneWidget);
    // No band numbers anywhere on the plan.
    expect(find.textContaining(RegExp(r'\b\d\.\d\b')), findsNothing);

    await tapText(tester, 'Start learning');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect((await saved()).completed, isTrue);
  });

  testWidgets('restart resumes on the same step with answers kept', (
    tester,
  ) async {
    await launch(tester);
    await tapText(tester, 'Continue as guest');
    await tapText(tester, 'Good user');
    await tapText(tester, 'Continue');
    await tapText(tester, "I haven't booked my exam yet");
    await tapText(tester, 'Continue');
    expect(find.text('Step 3 of 6'), findsOneWidget);

    await launch(tester); // simulated restart
    expect(find.text('Step 3 of 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 6'), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    expect(bottomButton(tester, 'Continue').onPressed, isNotNull);
  });

  testWidgets('skipping placement recommends from the self-assessment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.v1': jsonEncode(
        const OnboardingState(
          step: OnboardingStep.placement,
          level: EnglishLevel.intermediate,
        ).toJson(),
      ),
    });
    await launch(tester);
    expect(find.text('Step 6 of 6'), findsOneWidget);
    await tapText(tester, 'Skip');
    expect(find.text('Your study plan is ready'), findsOneWidget);
    expect(find.textContaining('self-assessment'), findsOneWidget);
    expect((await saved()).placementSkipped, isTrue);
  });

  testWidgets('non-guest goes to create account, then Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.v1': jsonEncode(
        const OnboardingState(step: OnboardingStep.plan).toJson(),
      ),
    });
    await launch(tester);
    await tapText(tester, 'Start learning');
    expect(find.text('Create your account'), findsOneWidget);
    expect((await saved()).completed, isFalse);
    await tapText(tester, 'Continue to Home');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect((await saved()).completed, isTrue);
  });

  testWidgets('placement shows an error with retry', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarding.v1': jsonEncode(
        const OnboardingState(step: OnboardingStep.placement).toJson(),
      ),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placementRepositoryProvider.overrideWithValue(_FailingPlacement()),
        ],
        child: const BandwiseApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load the placement check"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _FailingPlacement extends MockPlacementRepository {
  _FailingPlacement() : super(delay: Duration.zero);

  @override
  Future<Never> fetchQuestions() async => throw Exception('offline');
}
