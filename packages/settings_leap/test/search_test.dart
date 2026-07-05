import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_leap/settings_leap.dart';

String _inputs(BuildContext context) => 'Inputs';
String _mouse(BuildContext context) => 'Mouse';
String _persistence(BuildContext context) => 'Persistence';
String _behavior(BuildContext context) => 'Behavior';
String _theme(BuildContext context) => 'Theme';
String _appearance(BuildContext context) => 'Appearance';
String _profile(BuildContext context) => 'Profile';
String _profileName(BuildContext context) => 'Profile name';
String _nameA(BuildContext context) => 'Name A';
String _nameB(BuildContext context) => 'Name B';
String _treeTitle(BuildContext context) => 'Tree app bar';
String _pageTitle(BuildContext context) => 'Page app bar';

void main() {
  testWidgets('finds nested entries through their parent titles', (
    tester,
  ) async {
    const tree = SettingsLeapTree<Object?>({
      'inputs': SettingsLeapPage(
        displayName: _inputs,
        children: {'mouse': SettingsLeapPage(displayName: _mouse)},
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
        displayName: _persistence,
        keywords: ['behavior'],
      ),
      'top': SettingsLeapPage(
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

  testWidgets('finds dynamic list options and focuses the owning setting', (
    tester,
  ) async {
    const tree = SettingsLeapTree<String>({
      'profile': SettingsLeapPage(
        displayName: _profile,
        sections: {
          'identity': SettingsLeapSection(
            settings: [
              SettingsLeapListSetting<String, String>(
                id: 'name',
                displayName: _profileName,
                options: [
                  SettingsLeapOption(id: 'a', value: 'a', displayName: _nameA),
                  SettingsLeapOption(
                    id: 'b',
                    value: 'b',
                    displayName: _nameB,
                    description: 'Shown to collaborators.',
                  ),
                ],
                read: _readString,
                write: _writeString,
              ),
            ],
          ),
        },
      ),
    });

    late List<SettingsLeapSearchResult<String>> results;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            results = tree.search(context, 'a', 'collaborators');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(results.single.id, 'profile.identity.name.b');
    expect(results.single.focusId, 'profile.identity.name');
  });

  testWidgets('uses the page opener with search focus targets', (tester) async {
    const tree = SettingsLeapTree<String>({
      'profile': SettingsLeapPage(
        displayName: _profile,
        sections: {
          'identity': SettingsLeapSection(
            settings: [
              SettingsLeapListSetting<String, String>(
                id: 'name',
                displayName: _profileName,
                options: [
                  SettingsLeapOption(id: 'a', value: 'a', displayName: _nameA),
                  SettingsLeapOption(id: 'b', value: 'b', displayName: _nameB),
                ],
                read: _readString,
                write: _writeString,
              ),
            ],
          ),
        },
      ),
    });
    String? openedId;
    String? focusedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsLeapView<String>(
            tree: tree,
            state: 'a',
            compactWidth: 1000,
            onOpenPage: (context, id, page, focus) {
              openedId = id;
              focusedId = focus;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(SearchBar), 'Name B');
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Name B').last,
        matching: find.byType(ListTile),
      ),
    );

    expect(openedId, 'profile');
    expect(focusedId, 'profile.identity.name');
  });

  testWidgets('search opens nested page and highlights focused setting', (
    tester,
  ) async {
    const tree = SettingsLeapTree<Object?>({
      'inputs': SettingsLeapPage(
        displayName: _inputs,
        children: {
          'mouse': SettingsLeapPage(
            displayName: _mouse,
            sections: {
              'behavior': SettingsLeapSection(
                settings: [
                  SettingsLeapActionSetting(
                    id: 'theme',
                    displayName: _theme,
                    onTap: _noop,
                  ),
                ],
              ),
            },
          ),
        },
      ),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsLeapView<Object?>(
            tree: tree,
            state: null,
            compactWidth: 1000,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(SearchBar), 'Theme');
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Theme').last,
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Theme'), matching: find.byType(ListTile)),
    );
    expect(tile.selected, isTrue);
  });

  testWidgets('uses tree app bar builder with page overrides', (tester) async {
    const page = SettingsLeapPage<Object?>(displayName: _profile);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsLeapGeneratedPage<Object?>(
          page: page,
          state: null,
          appBarBuilder: _treeAppBar,
        ),
      ),
    );

    expect(find.text('Tree app bar'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsLeapGeneratedPage<Object?>(
          page: SettingsLeapPage<Object?>(
            displayName: _profile,
            appBarBuilder: _pageAppBar,
          ),
          state: null,
          appBarBuilder: _treeAppBar,
        ),
      ),
    );

    expect(find.text('Page app bar'), findsOneWidget);
    expect(find.text('Tree app bar'), findsNothing);
  });
}

Iterable<String> _appearanceKeywords(BuildContext context) => ['Look'];

void _noop(BuildContext context) {}

String _readString(String value) => value;

void _writeString(BuildContext context, String value) {}

PreferredSizeWidget _treeAppBar(
  BuildContext context,
  Object? state,
  bool inView,
  Widget title,
  List<Widget>? actions,
) {
  return AppBar(title: Text(_treeTitle(context)));
}

PreferredSizeWidget _pageAppBar(
  BuildContext context,
  Object? state,
  bool inView,
  Widget title,
  List<Widget>? actions,
) {
  return AppBar(title: Text(_pageTitle(context)));
}
