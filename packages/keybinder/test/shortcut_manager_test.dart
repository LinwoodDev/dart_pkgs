import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keybinder/keybinder.dart';

class TestIntent extends Intent {
  const TestIntent();
}

void main() {
  test('loads persisted shortcuts and exposes a ready future', () async {
    final store = _MemoryStore(
      jsonEncode({
        'save': {
          'keyId': LogicalKeyboardKey.keyS.keyId,
          'control': true,
          'shift': false,
          'alt': false,
          'meta': false,
        },
      }),
    );
    final keybinder = Keybinder(definitions: _definitions, store: store);

    await keybinder.ready;

    expectSingleActivator(
      keybinder.getActivator('save'),
      LogicalKeyboardKey.keyS,
      control: true,
    );
  });

  test('ignores invalid persisted shortcuts and keeps defaults', () async {
    final store = _MemoryStore(
      jsonEncode({
        'save': {'keyId': 'bad'},
        'open': {'keyId': -1},
      }),
    );
    final keybinder = Keybinder(definitions: _definitions, store: store);

    await keybinder.ready;

    expectSingleActivator(
      keybinder.getActivator('save'),
      LogicalKeyboardKey.keyS,
    );
    expectSingleActivator(
      keybinder.getActivator('open'),
      LogicalKeyboardKey.keyO,
    );
  });

  test('saves updated bindings', () async {
    final store = _MemoryStore(null);
    final keybinder = Keybinder(definitions: _definitions, store: store);

    await keybinder.ready;
    await keybinder.updateBinding(
      'save',
      const SingleActivator(LogicalKeyboardKey.keyS, control: true),
    );

    final saved = jsonDecode(store.saved!) as Map<String, dynamic>;
    expect(saved['save'], {
      'keyId': LogicalKeyboardKey.keyS.keyId,
      'control': true,
      'shift': false,
      'alt': false,
      'meta': false,
    });
  });

  test('reports unknown shortcut ids explicitly', () async {
    final keybinder = Keybinder(definitions: _definitions);

    await keybinder.ready;

    expect(keybinder.hasDefinition('missing'), isFalse);
    expect(keybinder.getActivatorOrNull('missing'), isNull);
    expect(() => keybinder.getActivator('missing'), throwsArgumentError);
  });

  test('rejects duplicate shortcut ids', () {
    expect(
      () => Keybinder(definitions: [_definitions.first, _definitions.first]),
      throwsArgumentError,
    );
  });
}

const _definitions = [
  ShortcutDefinition(
    id: 'save',
    intent: TestIntent(),
    defaultActivator: SingleActivator(LogicalKeyboardKey.keyS),
  ),
  ShortcutDefinition(
    id: 'open',
    intent: TestIntent(),
    defaultActivator: SingleActivator(LogicalKeyboardKey.keyO),
  ),
];

class _MemoryStore implements KeybinderStore {
  final String? value;
  String? saved;

  _MemoryStore(this.value);

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String data) async {
    saved = data;
  }
}

void expectSingleActivator(
  ShortcutActivator activator,
  LogicalKeyboardKey trigger, {
  bool control = false,
  bool shift = false,
  bool alt = false,
  bool meta = false,
}) {
  expect(activator, isA<SingleActivator>());
  final singleActivator = activator as SingleActivator;
  expect(singleActivator.trigger, trigger);
  expect(singleActivator.control, control);
  expect(singleActivator.shift, shift);
  expect(singleActivator.alt, alt);
  expect(singleActivator.meta, meta);
}
