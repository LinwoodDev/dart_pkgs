import 'package:flutter/material.dart';
import 'package:settings_leap/settings_leap.dart';

void main() => runApp(const SettingsLeapExample());

class SettingsLeapExample extends StatelessWidget {
  const SettingsLeapExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Settings Leap Example',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const _SettingsPage(),
  );
}

class _ExampleSettings {
  const _ExampleSettings({
    this.darkMode = false,
    this.textScale = 1,
    this.language = 'system',
  });

  final bool darkMode;
  final double textScale;
  final String language;

  _ExampleSettings copyWith({
    bool? darkMode,
    double? textScale,
    String? language,
  }) => _ExampleSettings(
    darkMode: darkMode ?? this.darkMode,
    textScale: textScale ?? this.textScale,
    language: language ?? this.language,
  );
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  var _settings = const _ExampleSettings();

  @override
  Widget build(BuildContext context) {
    final tree = SettingsLeapTree<_ExampleSettings>({
      'appearance': SettingsLeapPage(
        displayName: (_) => 'Appearance',
        icon: Icons.palette_outlined,
        description: 'Customize how the application looks.',
        sections: {
          'general': SettingsLeapSection(
            displayName: (_) => 'General',
            settings: [
              SettingsLeapBoolSetting(
                displayName: (_) => 'Dark mode',
                description: 'Use dark colors throughout the app.',
                help: 'Dark mode can reduce glare in low-light environments.',
                read: (state) => state.darkMode,
                write: (_, value) => setState(
                  () => _settings = _settings.copyWith(darkMode: value),
                ),
              ),
              SettingsLeapSliderSetting(
                displayName: (_) => 'Text scale',
                description: 'Adjust the size of interface text.',
                help:
                    'Enter an exact value or use the slider. The default is 1.0.',
                read: (state) => state.textScale,
                write: (_, value) => setState(
                  () => _settings = _settings.copyWith(textScale: value),
                ),
                min: 0.8,
                max: 2,
                defaultValue: 1,
                fractionDigits: 1,
              ),
              SettingsLeapListSetting<_ExampleSettings, String>(
                displayName: (_) => 'Language',
                description: 'Choose the interface language.',
                options: [
                  SettingsLeapOption(
                    id: 'system',
                    value: 'system',
                    displayName: (_) => 'System default',
                  ),
                  SettingsLeapOption(
                    id: 'english',
                    value: 'english',
                    displayName: (_) => 'English',
                  ),
                  SettingsLeapOption(
                    id: 'german',
                    value: 'german',
                    displayName: (_) => 'German',
                  ),
                ],
                read: (state) => state.language,
                write: (_, value) => setState(
                  () => _settings = _settings.copyWith(language: value),
                ),
              ),
            ],
          ),
        },
      ),
    });

    return Scaffold(
      body: SettingsLeapView(tree: tree, state: _settings),
    );
  }
}
