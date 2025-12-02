# Keybinder

> A Flutter package to easily manage and record custom keyboard shortcuts.

## Features

- 🎹 Record custom key combinations
- 💾 Abstract persistence (bring your own storage)
- 🔄 Reactive updates with `ChangeNotifier`
- 🌍 Localized UI
- 🛠 Modular and easy to integrate

## Usage

### 1. Define your Intents

```dart
class IncrementIntent extends Intent { const IncrementIntent(); }
class DecrementIntent extends Intent { const DecrementIntent(); }
```

### 2. Implement Persistence (Optional)

Implement `KeybinderStore` to save/load shortcuts.

```dart
class MyStore implements KeybinderStore {
  @override
  Future<String?> load() async {
    // Load from shared_preferences, file, etc.
    return null; 
  }

  @override
  Future<void> save(String data) async {
    // Save to shared_preferences, file, etc.
  }
}
```

### 3. Initialize Keybinder

```dart
final keybinder = Keybinder(
  definitions: [
    ShortcutDefinition(
      id: 'increment',
      intent: IncrementIntent(),
      defaultActivator: const SingleActivator(LogicalKeyboardKey.arrowUp),
    ),
    ShortcutDefinition(
      id: 'decrement',
      intent: DecrementIntent(),
      defaultActivator: const SingleActivator(LogicalKeyboardKey.arrowDown),
    ),
  ],
  store: MyStore(), // Optional
);
```

### 4. Use in your App

Wrap your app with `Shortcuts` and listen to `Keybinder`. Don't forget to add localizations!

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: keybinder,
      builder: (context, child) {
        return MaterialApp(
          localizationsDelegates: KeybinderLocalizations.localizationsDelegates,
          supportedLocales: KeybinderLocalizations.supportedLocales,
          home: Shortcuts(
            shortcuts: keybinder.getShortcuts(),
            child: Actions(
              actions: <Type, Action<Intent>>{
                IncrementIntent: CallbackAction<IncrementIntent>(onInvoke: (_) => print("Increment!")),
                DecrementIntent: CallbackAction<DecrementIntent>(onInvoke: (_) => print("Decrement!")),
              },
              child: HomePage(),
            ),
          ),
        );
      },
    );
  }
}
```

### 5. Record new keys

Use the `KeyRecorder` widget in your settings page.

```dart
KeyRecorder(
  currentActivator: keybinder.getActivator('increment'),
  onNewKey: (newKey) => keybinder.updateBinding('increment', newKey),
)
```
