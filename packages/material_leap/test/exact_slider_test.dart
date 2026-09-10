import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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

    await tester.enterText(find.byType(TextFormField), '3.75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changedValue, 3.75);
    expect(endedValue, 3.75);
  });
}
