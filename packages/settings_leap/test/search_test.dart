import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_leap/settings_leap.dart';

String _inputs(BuildContext context) => 'Inputs';
String _mouse(BuildContext context) => 'Mouse';
String _persistence(BuildContext context) => 'Persistence';
String _behavior(BuildContext context) => 'Behavior';
String _theme(BuildContext context) => 'Theme';
String _appearance(BuildContext context) => 'Appearance';

void main() {
  testWidgets('finds nested entries through their parent titles', (
    tester,
  ) async {
    const tree = SettingsLeapTree<Object?>({
      'inputs': SettingsLeapPage(
        id: 'inputs',
        displayName: _inputs,
        children: {'mouse': SettingsLeapPage(id: 'mouse', displayName: _mouse)},
      ),
    });

    late List<SettingsLeapSearchResult<Object?>> results;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            results = tree.search(context, null, 'inputs mouse');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(results.single.id, 'inputs.mouse');
  });

  testWidgets('ranks direct title matches before keyword matches', (
    tester,
  ) async {
    const tree = SettingsLeapTree<Object?>({
      'nested': SettingsLeapPage(
        id: 'nested',
        displayName: _persistence,
        keywords: ['behavior'],
      ),
      'top': SettingsLeapPage(
        id: 'top',
        displayName: _behavior,
        keywords: ['persistence'],
      ),
    });

    late List<SettingsLeapSearchResult<Object?>> results;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            results = tree.search(context, null, 'behavior');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(results.map((result) => result.id), ['top', 'nested']);
  });

  testWidgets('finds entries through localized keyword builders', (
    tester,
  ) async {
    const tree = SettingsLeapTree<Object?>({
      'personalization': SettingsLeapPage(
        id: 'personalization',
        displayName: _appearance,
        sections: {
          'theme': SettingsLeapSection(
            settings: [
              SettingsLeapActionSetting(
                displayName: _theme,
                keywordsBuilder: _appearanceKeywords,
                onTap: _noop,
              ),
            ],
          ),
        },
      ),
    });

    late List<SettingsLeapSearchResult<Object?>> results;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            results = tree.search(context, null, 'look');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(results.single.id, 'personalization.theme.setting0');
  });
}

Iterable<String> _appearanceKeywords(BuildContext context) => ['Look'];

void _noop(BuildContext context) {}
