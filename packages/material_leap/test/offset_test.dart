import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('inline size fields trim and round without moving the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: OffsetListTile(
              inline: true,
              title: const Text('Size'),
              value: const Offset(332.400000001, 314.1234567),
              onChanged: (_) {},
              fractionDigits: 3,
              trimTrailingZeros: true,
              titleSpacing: 24,
              spacing: 12,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.map((field) => field.controller!.text), ['332.4', '314.123']);
    for (final finder in [
      find.byType(TextField).first,
      find.byType(TextField).last,
    ]) {
      expect(
        tester.getCenter(finder).dy,
        closeTo(tester.getCenter(find.text('Size')).dy, 1),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('decimal editing remains intact until commit', (tester) async {
    var value = const Offset(332.4, 100);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 280,
              child: OffsetListTile(
                inline: true,
                value: value,
                fractionDigits: 3,
                trimTrailingZeros: true,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '42.');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '42.',
    );
    await tester.enterText(find.byType(TextField).first, '42.123456');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '42.123',
    );
    expect(value.dx, 42.123456);
    expect(value.dy, 100);
  });

  testWidgets(
    'narrow default layout is bounded and rejects non-finite values',
    (tester) async {
      Offset? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: OffsetListTile(
                title: const Text('Position'),
                value: Offset.zero,
                onChanged: (next) => changed = next,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byType(TextField).first).dy,
        greaterThan(tester.getBottomLeft(find.text('Position')).dy),
      );
      await tester.enterText(find.byType(TextField).first, 'NaN');
      await tester.pump();
      expect(changed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
