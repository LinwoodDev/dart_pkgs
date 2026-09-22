import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settings_leap/settings_leap.dart';

void main() {
  testWidgets('settings pages stay within the dialog', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tree = SettingsLeapTree<int>({
      'inputs': SettingsLeapPage(
        displayName: (context) => 'Inputs',
        sections: {
          'links': SettingsLeapSection(
            settings: [
              SettingsLeapActionSetting<int>(
                displayName: (context) => 'More',
                onTap: (context) {
                  expect(
                    SettingsLeapDialogNavigator.maybePush(
                      context,
                      const Scaffold(body: Text('More settings')),
                    ),
                    isTrue,
                  );
                },
              ),
            ],
          ),
        },
      ),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSettingsLeapDialog<void>(
                context: context,
                child: SettingsLeapView<int>(
                  tree: tree,
                  state: 0,
                  isDialog: true,
                ),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SettingsLeapPageTile<int>));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    final pageRect = tester.getRect(
      find.byType(SettingsLeapGeneratedPage<int>),
    );
    expect(dialogRect.contains(pageRect.topLeft), isTrue);
    expect(dialogRect.contains(pageRect.bottomRight), isTrue);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsLeapView<int>), findsOneWidget);

    await tester.tap(find.byType(SettingsLeapPageTile<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More settings'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });
}
