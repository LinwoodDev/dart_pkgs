import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Interface for persisting key bindings.
abstract class KeybinderStore {
  Future<String?> load();
  Future<void> save(String data);
}

/// Defines a shortcut with an ID, display name, intent, and default activator.
class ShortcutDefinition {
  final String id;
  final Intent intent;
  final ShortcutActivator defaultActivator;

  const ShortcutDefinition({
    required this.id,
    required this.intent,
    required this.defaultActivator,
  });
}

/// Manages keyboard shortcuts, including persistence and state management.
class Keybinder with ChangeNotifier {
  final Map<String, ShortcutDefinition> _definitionsById = {};
  final Map<String, ShortcutActivator> _activators = {};
  final KeybinderStore? _store;

  /// Creates a Keybinder with a list of shortcut definitions.
  ///
  /// [definitions] is a list of [ShortcutDefinition]s.
  /// [store] is an optional persistence mechanism.
  Keybinder({
    required List<ShortcutDefinition> definitions,
    KeybinderStore? store,
  }) : _store = store {
    for (final def in definitions) {
      _definitionsById[def.id] = def;
      _activators[def.id] = def.defaultActivator;
    }
    _load();
  }

  /// Returns the current activator for the given ID.
  ShortcutActivator getActivator(String id) {
    final def = _definitionsById[id];
    if (def == null) return const SingleActivator(LogicalKeyboardKey.keyA);
    return _activators[id] ?? def.defaultActivator;
  }

  /// Returns the definition for the given ID.
  ShortcutDefinition? getDefinition(String id) {
    return _definitionsById[id];
  }

  /// Returns all registered definitions.
  Iterable<ShortcutDefinition> get definitions => _definitionsById.values;

  /// Generates the map of activators to intents for use in the [Shortcuts] widget.
  ///
  /// [ids] is a list of IDs that should be active.
  Map<ShortcutActivator, Intent> getShortcuts([List<String>? ids]) {
    final result = <ShortcutActivator, Intent>{};
    for (final id in ids ?? _definitionsById.keys) {
      final def = _definitionsById[id];
      if (def != null) {
        final activator = _activators[id] ?? def.defaultActivator;
        result[activator] = def.intent;
      }
    }
    return result;
  }

  /// Updates the binding for a specific ID.
  Future<void> updateBinding(String id, SingleActivator newActivator) async {
    final def = _definitionsById[id];
    if (def == null) return;

    _activators[id] = newActivator;
    notifyListeners();
    await _save();
  }

  /// Resets the binding for a specific ID to its default.
  Future<void> resetBinding(String id) async {
    final def = _definitionsById[id];
    if (def == null) return;

    _activators[id] = def.defaultActivator;
    notifyListeners();
    await _save();
  }

  /// Resets all bindings to their defaults.
  Future<void> resetToDefaults() async {
    _activators.clear();
    for (final def in _definitionsById.values) {
      _activators[def.id] = def.defaultActivator;
    }
    notifyListeners();
    await _save();
  }

  // --- Persistence Logic ---

  Future<void> _save() async {
    if (_store == null) return;

    final Map<String, dynamic> jsonMap = {};

    _activators.forEach((id, activator) {
      if (activator is SingleActivator) {
        jsonMap[id] = {
          'keyId': activator.trigger.keyId,
          'control': activator.control,
          'shift': activator.shift,
          'alt': activator.alt,
          'meta': activator.meta,
        };
      }
    });

    await _store.save(jsonEncode(jsonMap));
  }

  Future<void> _load() async {
    if (_store == null) return;

    final String? jsonString = await _store.load();

    if (jsonString != null) {
      try {
        final Map<String, dynamic> loaded = jsonDecode(jsonString);

        for (final id in _definitionsById.keys) {
          if (loaded.containsKey(id)) {
            final value = loaded[id];
            final activator = SingleActivator(
              LogicalKeyboardKey.findKeyByKeyId(value['keyId']) ??
                  LogicalKeyboardKey.keyA,
              control: value['control'] ?? false,
              shift: value['shift'] ?? false,
              alt: value['alt'] ?? false,
              meta: value['meta'] ?? false,
            );
            _activators[id] = activator;
          }
        }
      } catch (e) {
        debugPrint("Error loading shortcuts: $e");
      }
    }
    notifyListeners();
  }
}
