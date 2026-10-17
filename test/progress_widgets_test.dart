import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLinearProgress', () {
    for (final dir in TextDirection.values) {
      testWidgets('track fills the width at 0% in a start-aligned Column '
          '(${dir.name})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: dir,
              child: const Scaffold(
                body: SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('Label'), AppLinearProgress(value: 0)],
                  ),
                ),
              ),
            ),
          ),
        );
        final bar = tester.getSize(find.byType(AppLinearProgress));
        expect(bar.width, 300);
        final track = find.descendant(
          of: find.byType(AppLinearProgress),
          matching: find.byType(ColoredBox),
        );
        expect(tester.getSize(track).width, 300);
      });
    }
  });
}
