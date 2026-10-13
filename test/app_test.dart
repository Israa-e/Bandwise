import 'package:bandwise/app.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/dev_gallery/presentation/component_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('app starts on Home and switches tabs', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const ProviderScope(child: BandwiseApp()));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(
      find.text('Your daily plan, streak and next lesson will appear here.'),
      findsOneWidget,
    );

    for (final tab in ['Learn', 'Practice', 'Progress', 'Profile', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, tab), findsOneWidget);
    }
  });

  testWidgets('Profile opens the component gallery in debug', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const ProviderScope(child: BandwiseApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Component gallery'));
    await tester.pumpAndSettle();

    expect(find.byType(ComponentGalleryScreen), findsOneWidget);
  });

  for (final rtl in [false, true]) {
    testWidgets('gallery renders every section without overflow '
        '(${rtl ? 'RTL' : 'LTR'})', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(const ProviderScope(child: BandwiseApp()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Component gallery'));
      await tester.pumpAndSettle();

      if (rtl) {
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
      }

      // Scroll to the end, building every section on the way.
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('No saved words yet'),
        400,
        scrollable: list,
      );
      expect(find.text('No saved words yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('quiz demo shows correct and incorrect states', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const MaterialApp(home: ComponentGalleryScreen()));
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('were finalising'),
      300,
      scrollable: list,
    );
    await tester.ensureVisible(find.text('were finalising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('were finalising'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Check answer'),
      200,
      scrollable: list,
    );
    await tester.ensureVisible(find.text('Check answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    Finder badgeIn(String option, String badge) => find.descendant(
      of: find.widgetWithText(SelectionCard, option),
      matching: find.text(badge),
    );
    expect(badgeIn('had finalised', 'Correct'), findsOneWidget);
    expect(badgeIn('were finalising', 'Incorrect'), findsOneWidget);
  });
}
