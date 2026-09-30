import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settings_leap/settings_leap.dart';

enum _Controls { full, input }

void main() {
  const longLabel = 'Full (slider, text field and buttons)';
  for (final width in [232.0, 600.0]) {
    for (final textScale in [1.0, 2.0]) {
      for (final useEnum in [false, true]) {
        testWidgets(
          '${useEnum ? "enum" : "list"} values fit at width $width and text scale $textScale',
          (tester) async {
            _Controls? written;
            final setting = useEnum
                ? SettingsLeapEnumSetting<_Controls, _Controls>(
                    displayName: (context) => 'Zoom panel controls',
                    description: 'Choose the controls for zoom and rotation.',
                    help: 'Reset buttons remain available in every layout.',
                    icon: Icons.zoom_in,
                    values: _Controls.values,
                    read: (state) => state,
                    write: (context, value) => written = value,
                    valueLabel: (context, value) =>
                        value == _Controls.full ? longLabel : 'Text field',
                    valueLeadingBuilder: (context, value) =>
                        const Icon(Icons.zoom_in),
                  )
                : SettingsLeapListSetting<_Controls, _Controls>(
                    displayName: (context) => 'Zoom panel controls',
                    description: 'Choose the controls for zoom and rotation.',
                    help: 'Reset buttons remain available in every layout.',
                    icon: Icons.zoom_in,
                    options: [
                      SettingsLeapOption(
                        id: 'full',
                        value: _Controls.full,
                        displayName: (context) => longLabel,
                        leadingBuilder: (context) => const Icon(Icons.zoom_in),
                      ),
                      SettingsLeapOption(
                        id: 'input',
                        value: _Controls.input,
                        displayName: (context) => 'Text field',
                      ),
                    ],
                    read: (state) => state,
                    write: (context, value) => written = value,
                  );

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MediaQuery(
                    data: MediaQueryData(
                      textScaler: TextScaler.linear(textScale),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: width,
                        child: SingleChildScrollView(
                          child: Builder(
                            builder: (context) =>
                                setting.buildTile(context, _Controls.full),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            expect(tester.takeException(), isNull);
            expect(find.text(longLabel), findsOneWidget);
            expect(
              find.text('Choose the controls for zoom and rotation.'),
              findsOneWidget,
            );
            final labelRect = tester.getRect(find.text(longLabel));
            final tileRect = tester.getRect(find.byType(ListTile));
            expect(tileRect.contains(labelRect.topLeft), isTrue);
            expect(tileRect.contains(labelRect.bottomRight), isTrue);

            await tester.ensureVisible(find.text(longLabel));
            await tester.pumpAndSettle();
            await tester.tap(find.text(longLabel));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Text field'));
            await tester.pumpAndSettle();
            expect(written, _Controls.input);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
