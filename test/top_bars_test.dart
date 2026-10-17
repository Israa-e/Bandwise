import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool hasShadow(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(TopBarSurface),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return (box.decoration as BoxDecoration).boxShadow != null;
  }

  for (final (name, bar) in <(String, PreferredSizeWidget)>[
    ('OnboardingTopBar', const OnboardingTopBar(step: 1, totalSteps: 6)),
    ('AuthTopBar', const AuthTopBar()),
  ]) {
    testWidgets('$name shows a shadow only when content is scrolled under', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: bar,
            body: ListView(
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('Row $i')),
              ],
            ),
          ),
        ),
      );
      expect(hasShadow(tester), isFalse);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(hasShadow(tester), isTrue);

      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(hasShadow(tester), isFalse);
    });
  }
}
