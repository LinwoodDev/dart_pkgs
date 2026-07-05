# Settings Leap

> Flutter settings framework for building searchable, expandable settings views

## Features

* 🚀 Model settings as a tree of pages, sections, and entries
* 🔎 Search pages, sections, descriptions, and custom keywords
* 🎨 Keep full control over localization, icons, actions, and custom page bodies
* 🧩 Use built-in boolean, enum, list, action, and custom settings
* 📱 Responsive Material layout for compact and wide screens

## Getting started

Add the package to your project using a git dependency.

```yaml
dependencies:
  settings_leap:
    git:
      url: https://github.com/LinwoodDev/dart_pkgs.git
      path: packages/settings_leap
```

## Usage

Create a settings tree, pass your app state to it, and render it with `SettingsLeapView`.

```dart
import 'package:flutter/material.dart';
import 'package:settings_leap/settings_leap.dart';

enum SyncMode { off, manual, automatic }

class AppSettings {
  const AppSettings({required this.darkMode, required this.syncMode});

  final bool darkMode;
  final SyncMode syncMode;
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final tree = SettingsLeapTree<AppSettings>({
      'general': SettingsLeapPage(
        displayName: (context) => 'General',
        icon: Icons.settings,
        sections: {
          'appearance': SettingsLeapSection(
            displayName: (context) => 'Appearance',
            settings: [
              SettingsLeapBoolSetting(
                id: 'darkMode',
                displayName: (context) => 'Dark mode',
                description: 'Use a darker color scheme.',
                read: (state) => state.darkMode,
                write: (context, value) {
                  // Update your app state here.
                },
              ),
            ],
          ),
          'sync': SettingsLeapSection(
            displayName: (context) => 'Sync',
            settings: [
              SettingsLeapEnumSetting<AppSettings, SyncMode>(
                id: 'syncMode',
                displayName: (context) => 'Sync mode',
                keywords: const ['cloud', 'backup'],
                values: SyncMode.values,
                read: (state) => state.syncMode,
                write: (context, value) {
                  // Update your app state here.
                },
                valueLabel: (context, value) => switch (value) {
                  SyncMode.off => 'Off',
                  SyncMode.manual => 'Manual',
                  SyncMode.automatic => 'Automatic',
                },
                valueDescription: (context, value) => switch (value) {
                  SyncMode.off => 'Never sync automatically.',
                  SyncMode.manual => 'Sync only when requested.',
                  SyncMode.automatic => 'Keep data synced in the background.',
                },
              ),
            ],
          ),
        },
      ),
    }, appBarBuilder: _buildSettingsAppBar);
    });

    return SettingsLeapView(
      tree: tree,
      state: settings,
      title: (context) => 'Settings',
      searchHint: (context) => 'Search settings',
    );
  }
}

PreferredSizeWidget _buildSettingsAppBar(
  BuildContext context,
  AppSettings settings,
  bool inView,
  Widget title,
  List<Widget>? actions,
) {
  return AppBar(
    title: title,
    actions: actions,
    automaticallyImplyLeading: !inView,
  );
}
```

## Custom entries

Use `SettingsLeapActionSetting` for tap actions and `SettingsLeapCustomSetting` when a setting needs its own widget.

```dart
SettingsLeapActionSetting<AppSettings>(
  displayName: (context) => 'Reset settings',
  icon: Icons.restore,
  onTap: (context) {
    // Reset your settings here.
  },
);
```

## Dynamic options

Use `SettingsLeapListSetting` when options come from dynamic data with stable ids and display names.

```dart
SettingsLeapListSetting<AppSettings, String>(
  id: 'workspace',
  displayName: (context) => 'Workspace',
  options: [
    SettingsLeapOption(
      id: 'personal',
      value: 'personal',
      displayName: (context) => 'Personal',
      description: 'Only visible to you.',
    ),
    SettingsLeapOption(
      id: 'team',
      value: 'team',
      displayName: (context) => 'Team',
      description: 'Shared with collaborators.',
    ),
  ],
  read: (state) => 'personal',
  write: (context, value) {
    // Update your app state here.
  },
);
```

## Routing

`SettingsLeapView` can delegate page opening to your app router without depending on a routing package.

```dart
SettingsLeapView(
  tree: tree,
  state: settings,
  onOpenPage: (context, id, page, focusedId) {
    // For example with go_router:
    // context.go('/settings/$id', extra: focusedId);
  },
);
```

When rendering routed pages yourself, pass the same id and optional focus target to `SettingsLeapGeneratedPage`.

```dart
SettingsLeapGeneratedPage(
  page: tree.pages[id]!,
  pageId: id,
  focusedId: focusedId,
  state: settings,
);
```

## Search

`SettingsLeapTree` can also be searched manually. Results include the matched node, its id, score, breadcrumb, and optional `focusId`.

```dart
final results = tree.search(context, settings, 'sync');

for (final result in results) {
  debugPrint(result.breadcrumb(context));
}
```
