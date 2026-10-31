import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settings_leap/settings_leap.dart';

void main() {
  testWidgets(
    'multi-select options update independently and remain searchable',
    (tester) async {
      var state = <String>{'slider', 'buttons'};
      late StateSetter rebuild;
      final setting = SettingsLeapMultiSelectSetting<Set<String>, String>(
        id: 'controls',
        displayName: (_) => 'Camera controls',
        description: 'Choose independent controls.',
        help: 'Reset remains available.',
        icon: Icons.zoom_in,
        emptySelectionLabel: (_) => 'Reset only',
        options: [
          SettingsLeapOption(
            id: 'slider',
            value: 'slider',
            displayName: (_) => 'Slider',
          ),
          SettingsLeapOption(
            id: 'input',
            value: 'input',
            displayName: (_) => 'Text field',
            keywords: ['typing'],
          ),
          SettingsLeapOption(
            id: 'buttons',
            value: 'buttons',
            displayName: (_) => 'Buttons',
          ),
        ],
        read: (state) => state,
        write: (_, value) => rebuild(() => state = value),
      );
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 232,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      rebuild = setState;
                      pageContext = context;
                      return setting.buildTile(context, state);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Slider, Buttons'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final tree = SettingsLeapTree<Set<String>>({
        'view': SettingsLeapPage(
          displayName: (_) => 'View',
          sections: {
            'camera': SettingsLeapSection(settings: [setting]),
          },
        ),
      });
      final result = tree.search(pageContext, state, 'typing').single;
      expect(result.id, 'view.camera.controls.input');
      expect(result.focusId, 'view.camera.controls');

      await tester.tap(find.text('Camera controls'));
      await tester.pumpAndSettle();
      Future<void> toggle(String label) async {
        await tester.tap(find.widgetWithText(CheckboxListTile, label));
        await tester.pumpAndSettle();
      }

      await toggle('Slider');
      expect(state, {'buttons'});
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      await toggle('Buttons');
      expect(state, isEmpty);
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((tile) => tile.value == false),
        isTrue,
      );
      await toggle('Text field');
      expect(state, {'input'});
      await toggle('Slider');
      expect(state, {'input', 'slider'});
      await toggle('Text field');
      await toggle('Slider');
      Navigator.of(tester.element(find.byType(CheckboxListTile).first)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Reset only'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
