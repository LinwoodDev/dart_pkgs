import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keybinder/keybinder.dart';

void main() {
  runApp(const MyApp());
}

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class DecrementIntent extends Intent {
  const DecrementIntent();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Keybinder keybinder;

  @override
  void initState() {
    super.initState();
    keybinder = Keybinder(
      definitions: [
        const ShortcutDefinition(
          id: 'increment',
          displayName: 'Increment Counter',
          intent: IncrementIntent(),
          defaultActivator: SingleActivator(LogicalKeyboardKey.arrowUp),
        ),
        const ShortcutDefinition(
          id: 'decrement',
          displayName: 'Decrement Counter',
          intent: DecrementIntent(),
          defaultActivator: SingleActivator(LogicalKeyboardKey.arrowDown),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: keybinder,
      builder: (context, child) {
        return MaterialApp(
          title: 'Keybinder Example',
          localizationsDelegates: const [
            ...KeybinderLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            ...KeybinderLocalizations.supportedLocales,
            Locale('en'),
          ],
          home: Shortcuts(
            shortcuts: keybinder.getShortcuts(),
            child: Actions(
              actions: <Type, Action<Intent>>{
                IncrementIntent: CallbackAction<IncrementIntent>(
                  onInvoke: (_) => debugPrint("Increment Triggered!"),
                ),
                DecrementIntent: CallbackAction<DecrementIntent>(
                  onInvoke: (_) => debugPrint("Decrement Triggered!"),
                ),
              },
              child: HomePage(keybinder: keybinder),
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final Keybinder keybinder;

  const HomePage({super.key, required this.keybinder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keybinder Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Press Arrow Up/Down to see logs in console."),
            const SizedBox(height: 20),
            const Text("Increment Key:"),
            KeyRecorderButton(
              currentActivator: keybinder.getActivator(IncrementIntent),
              onNewKey: (newKey) =>
                  keybinder.updateBinding(IncrementIntent, newKey),
              onReset: () => keybinder.resetBinding(IncrementIntent),
            ),
            const SizedBox(height: 20),
            const Text("Decrement Key:"),
            KeyRecorderButton(
              currentActivator: keybinder.getActivator(DecrementIntent),
              onNewKey: (newKey) =>
                  keybinder.updateBinding(DecrementIntent, newKey),
              onReset: () => keybinder.resetBinding(DecrementIntent),
            ),
            const SizedBox(height: 20),
            const Text("List Tile Example:"),
            KeyRecorderListTile(
              title: const Text("Increment (Tile)"),
              currentActivator: keybinder.getActivator(IncrementIntent),
              onNewKey: (newKey) =>
                  keybinder.updateBinding(IncrementIntent, newKey),
              onReset: () => keybinder.resetBinding(IncrementIntent),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => keybinder.resetToDefaults(),
              child: const Text("Reset to Defaults"),
            ),
          ],
        ),
      ),
    );
  }
}
