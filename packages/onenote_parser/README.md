# onenote_parser

Dart and Flutter bindings for [onenote.rs](https://github.com/msiemens/onenote.rs),
built with `flutter_rust_bridge` and Native Assets.

## Supported inputs

- Native: `.one`, `.onetoc2`, and `.onepkg` paths.
- Native and web: `.one` and `.onepkg` bytes.

A loose `.onetoc2` notebook references sibling `.one` files, so browser clients
should provide a `.onepkg` archive when parsing a complete notebook.

## Usage

```dart
import 'dart:typed_data';

import 'package:onenote_parser/onenote_parser.dart';

Future<OneNoteSection> readSection(Uint8List bytes) async {
  await RustLib.init();
  return parseSectionBytes(data: bytes, fileName: 'section.one');
}

Future<OneNoteNotebook> readNotebook(Uint8List onepkgBytes) async {
  await RustLib.init();
  return parsePackageBytes(data: onepkgBytes);
}
```

The returned document tree contains ordinary Dart fields—there are no opaque
handles for notebooks, sections, pages, outlines, text, tables, images,
attachments, or ink. Rust enums are generated as Freezed sealed classes, so
variants can be handled directly:

```dart
for (final entry in notebook.entries) {
  entry.when(
    section: (section) => print(section.displayName),
    sectionGroup: (group) => print(group.displayName),
  );
}
```

The example app opens `.one` and `.onepkg` files with a platform file picker,
walks the typed document tree, and runs on native platforms and web.

## Regenerating

The package pins:

- `flutter_rust_bridge` `2.13.0-beta.2`
- `CodeDoctorDE/onenote.rs` commit
  `99c53cc856f7f93b41024eeb75b10a5b1be25c03`

The fork contains a small compatibility fix for real-world rich-text nodes that
omit their paragraph-style reference. Those nodes are preserved with default
formatting and produce a parser warning.

After changing Rust APIs, run:

```bash
flutter_rust_bridge_codegen generate
```
