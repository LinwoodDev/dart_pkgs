import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('text keeps precision and step controls use modifiers', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberInput(
            value: 2,
            min: 0,
            max: 20,
            fractionDigits: 0,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '2.75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(changed, 2.75);

    tester.widget<IconButton>(find.byType(IconButton).last).onPressed!();
    await tester.pump();
    expect(changed, 3.75);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    tester.widget<IconButton>(find.byType(IconButton).last).onPressed!();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(changed, 8.75);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    tester.widget<IconButton>(find.byType(IconButton).last).onPressed!();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(changed, closeTo(8.85, 0.0001));
  });

  testWidgets('arrow keys and wheel change the value', (tester) async {
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberInput(
            value: 2,
            min: 0,
            max: 10,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(changed, 3);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(TextField)),
        scrollDelta: const Offset(0, 1),
      ),
    );
    expect(changed, 2);
  });

  testWidgets('Ctrl-drag adjusts the field horizontally', (tester) async {
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberInput(
            value: 2,
            min: 0,
            max: 10,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TextField)),
    );
    await gesture.moveBy(const Offset(16, 0));
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(changed, 4);
  });
}
