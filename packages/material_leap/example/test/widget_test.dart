// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

import 'package:material_leap_example/main.dart';

void main() {
  testWidgets('shows demo sections', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MyApp());

    expect(find.text('Material Leap Demo'), findsOneWidget);
    expect(find.text('Widgets'), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(AdvancedTextField),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dialogs and sheets'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dialogs and sheets'), findsOneWidget);
    semantics.dispose();
  });
}
