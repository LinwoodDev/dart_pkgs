import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:keybinder/keybinder.dart';

void main() {
  testWidgets('uses readable labels for space and media track keys', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: KeybinderLocalizations.localizationsDelegates,
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      ShortcutLocalizer.localize(
        context,
        const SingleActivator(LogicalKeyboardKey.space),
      ),
      'Space',
    );
    expect(
      ShortcutLocalizer.localize(
        context,
        const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious),
      ),
      'Media Previous',
    );
    expect(
      ShortcutLocalizer.localize(
        context,
        const SingleActivator(LogicalKeyboardKey.mediaTrackNext, control: true),
      ),
      'Ctrl+Media Next',
    );
  });
}
