import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
  late final Future<void> _ready;

  /// Creates a Keybinder with a list of shortcut definitions.
  ///
  /// [definitions] is a list of [ShortcutDefinition]s.
  /// [store] is an optional persistence mechanism.
  Keybinder({
    required List<ShortcutDefinition> definitions,
    KeybinderStore? store,
  }) : _store = store {
    for (final def in definitions) {
      if (_definitionsById.containsKey(def.id)) {
        throw ArgumentError.value(
          def.id,
          'definitions',
          'Shortcut IDs must be unique.',
        );
      }

      _definitionsById[def.id] = def;
      _activators[def.id] = def.defaultActivator;
    }
    _ready = _load();
  }

  /// Completes after any persisted shortcuts have been loaded.
  Future<void> get ready => _ready;

  /// Returns the current activator for the given ID.
  ShortcutActivator getActivator(String id) {
    final activator = getActivatorOrNull(id);
    if (activator == null) {
      throw ArgumentError.value(id, 'id', 'No shortcut is registered with id.');
    }
    return activator;
  }

  /// Returns the current activator for the given ID, or null if it is unknown.
  ShortcutActivator? getActivatorOrNull(String id) {
    final def = _definitionsById[id];
    if (def == null) return null;
    return _activators[id] ?? def.defaultActivator;
  }

  /// Returns whether a shortcut definition exists for the given ID.
  bool hasDefinition(String id) => _definitionsById.containsKey(id);

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
  Future<void> updateBinding(String id, ShortcutActivator newActivator) async {
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

    final jsonMap = <String, Object>{};

    _activators.forEach((id, activator) {
      if (activator is SingleActivator) {
        jsonMap[id] = _singleActivatorToJson(activator);
      }
    });

    await _store.save(jsonEncode(jsonMap));
  }

  Future<void> _load() async {
    if (_store == null) return;

    final jsonString = await _store.load();

    if (jsonString != null) {
      try {
        final loaded = jsonDecode(jsonString);

        if (loaded is Map<String, dynamic>) {
          for (final id in _definitionsById.keys) {
            final value = loaded[id];
            final activator = _readSingleActivator(value);
            if (activator != null) {
              _activators[id] = activator;
            }
          }
        }
      } catch (error) {
        debugPrint('Error loading shortcuts: $error');
      }
    }
    notifyListeners();
  }

  Map<String, Object> _singleActivatorToJson(SingleActivator activator) {
    return {
      'keyId': activator.trigger.keyId,
      'control': activator.control,
      'shift': activator.shift,
      'alt': activator.alt,
      'meta': activator.meta,
    };
  }

  SingleActivator? _readSingleActivator(Object? value) {
    if (value is Map<String, dynamic>) {
      return _singleActivatorFromJson(value);
    }
    if (value is Map) {
      return _singleActivatorFromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  SingleActivator? _singleActivatorFromJson(Map<String, dynamic> json) {
    final keyId = json['keyId'];

    if (keyId is! int) {
      return null;
    }

    final trigger = LogicalKeyboardKey.findKeyByKeyId(keyId);

    if (trigger == null) {
      return null;
    }

    bool readModifier(String key) => json[key] == true;

    return SingleActivator(
      trigger,
      control: readModifier('control'),
      shift: readModifier('shift'),
      alt: readModifier('alt'),
      meta: readModifier('meta'),
    );
  }
}
