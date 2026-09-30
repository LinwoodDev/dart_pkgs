import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('inputWidth sizes the number field', (tester) async {
    Future<void> showSlider(double? width) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: width == null
                ? const ExactSlider()
                : ExactSlider(inputWidth: width),
          ),
        ),
      ),
    );

    await showSlider(null);
    expect(tester.getSize(find.byType(NumberInput)).width, 80);

    await showSlider(110);
    expect(tester.getSize(find.byType(NumberInput)).width, 110);
  });

  testWidgets('sliderStep snaps only slider interactions', (tester) async {
    double? changedValue;
    double? endedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExactSlider(
            value: 2.25,
            min: 0.1,
            max: 70,
            sliderStep: 1,
            onChanged: (value) => changedValue = value,
            onChangeEnd: (value) => endedValue = value,
          ),
        ),
      ),
    );

    var slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(3.6);
    await tester.pump();
    expect(changedValue, 4);

    slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeEnd!(4.4);
    expect(endedValue, 4);

    await tester.enterText(find.byType(TextField), '3.');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '3.',
    );

    await tester.enterText(find.byType(TextField), '3.75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changedValue, 3.75);
    expect(endedValue, 3.75);
  });

  testWidgets('optional step buttons use custom icons and remain bounded', (
    tester,
  ) async {
    double? changed, ended;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: ExactSlider(
            value: 2.25,
            min: 0,
            max: 4,
            sliderStep: 1,
            showButtons: true,
            decrementIcon: const Icon(Icons.remove, key: ValueKey('decrement')),
            incrementIcon: const Icon(Icons.add, key: ValueKey('increment')),
            onChanged: (v) => changed = v,
            onChangeEnd: (v) => ended = v,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('decrement')), findsOneWidget);
    expect(find.byKey(const ValueKey('increment')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('increment')));
    await tester.pump();
    expect(changed, 3.25);
    expect(ended, 3.25);
    await tester.tap(find.byKey(const ValueKey('increment')));
    await tester.pump();
    expect(changed, 4);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byKey(const ValueKey('increment')),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    await tester.enterText(find.byType(TextField), '2.75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(changed, 2.75);
    expect(ended, 2.75);
  });
}
