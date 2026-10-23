import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('linwood.dev/lw_sysapi/drop');
  const codec = StandardMethodCodec();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
  });

  Future<void> event(
    WidgetTester tester,
    String phase,
    Offset position, [
    List<Object?> items = const [],
  ]) async {
    final done = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(
            MethodCall('dropEvent', {
              'phase': phase,
              'x': position.dx,
              'y': position.dy,
              'items': items,
            }),
          ),
          (_) => done.complete(),
        );
    await done.future;
    await tester.pump();
  }

  testWidgets('drops use target-local coordinates and preserve all items', (
    tester,
  ) async {
    SystemDropDetails? received;
    final hover = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(left: 100, top: 80),
            child: SizedBox(
              width: 200,
              height: 150,
              child: SystemDropTarget(
                onDrop: (details) => received = details,
                onHover: hover.add,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );
    await event(tester, 'hover', const Offset(130, 110));
    expect(hover, [true]);
    await event(tester, 'drop', const Offset(130, 110), [
      {'path': r'C:\References\image one.png'},
      {'path': '/tmp/two.svg'},
    ]);
    expect(received!.localPosition, const Offset(30, 30));
    expect(received!.items.map((e) => e.uri), [
      Uri.parse('file:///C:/References/image%20one.png'),
      Uri.file('/tmp/two.svg'),
    ]);
    expect(hover, [true, false]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('an opaque toolbar or modal surface blocks the target', (
    tester,
  ) async {
    var drops = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: SystemDropTarget(
                onDrop: (_) {
                  drops++;
                },
                child: const ColoredBox(color: Colors.white),
              ),
            ),
            const Positioned(
              left: 0,
              top: 0,
              width: 200,
              height: 200,
              child: ColoredBox(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
    await event(tester, 'drop', const Offset(50, 50));
    expect(drops, 0);
    await event(tester, 'drop', const Offset(300, 300));
    expect(drops, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    'the innermost target receives a drop and disabled targets do not',
    (tester) async {
      var outer = 0, inner = 0;
      Widget build(bool enabled) => MaterialApp(
        home: SystemDropTarget(
          onDrop: (_) {
            outer++;
          },
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: SystemDropTarget(
                enabled: enabled,
                onDrop: (_) {
                  inner++;
                },
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(true));
      await event(tester, 'drop', const Offset(400, 300));
      expect((outer, inner), (0, 1));
      await tester.pumpWidget(build(false));
      await event(tester, 'drop', const Offset(400, 300));
      expect((outer, inner), (1, 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets('async imports block reentry and report errors through onError', (
    tester,
  ) async {
    final pending = Completer<void>();
    var drops = 0;
    Object? error;
    await tester.pumpWidget(
      MaterialApp(
        home: SystemDropTarget(
          showFeedback: true,
          onDrop: (_) {
            drops++;
            return pending.future;
          },
          onError: (value, _) => error = value,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );
    await event(tester, 'drop', const Offset(100, 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await event(tester, 'drop', const Offset(100, 100));
    expect(drops, 1);
    pending.completeError(StateError('failed import'));
    await tester.pump();
    expect(error, isA<StateError>());
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
