import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_leap/material_leap.dart';

void main() {
  testWidgets('switch changes without invoking the tile action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: _AdvancedSwitchHost()),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Switch)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(4, 2));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();

    final state = tester.state<_AdvancedSwitchHostState>(
      find.byType(_AdvancedSwitchHost),
    );
    expect(state.value, isTrue);
    expect(state.changeCount, 1);
    expect(state.tileTapCount, 0);
    expect(
      find.ancestor(of: find.byType(Switch), matching: find.byType(ListTile)),
      findsOneWidget,
    );
  });
}

class _AdvancedSwitchHost extends StatefulWidget {
  const _AdvancedSwitchHost();

  @override
  State<_AdvancedSwitchHost> createState() => _AdvancedSwitchHostState();
}

class _AdvancedSwitchHostState extends State<_AdvancedSwitchHost> {
  bool value = false;
  int changeCount = 0;
  int tileTapCount = 0;

  @override
  Widget build(BuildContext context) {
    return AdvancedSwitchListTile(
      title: const Text('Advanced setting'),
      trailing: const Text('Option'),
      value: value,
      onTap: () => setState(() => tileTapCount++),
      onChanged: (value) => setState(() {
        this.value = value;
        changeCount++;
      }),
    );
  }
}
