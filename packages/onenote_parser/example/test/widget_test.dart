import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onenote_parser_example/main.dart';

void main() {
  testWidgets('shows file picker welcome screen', (tester) async {
    await tester.pumpWidget(MyApp(pickFile: () async => null));

    expect(find.text('OneNote parser'), findsOneWidget);
    expect(find.text('Read a OneNote file'), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-file')));
    await tester.pump();

    expect(find.text('Read a OneNote file'), findsOneWidget);
  });
}
