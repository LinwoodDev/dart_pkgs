# lw_sysapi

> Utility methods to access system information

## Features

|                Method | Description                         | Windows | Linux | macOS |  iOS  | Web (JS) | Web (WASM) | Android |
| --------------------: | :---------------------------------- | :-----: | :---: | :---: | :---: | :------: | :--------: | :-----: |
|            `getFonts` | Get all system fonts                |    ✅    |   ✅   |   ❌   |   ❌   |    ✅     |     ✅      |    ❌    |
| `getClipboardManager` | Read and write typed clipboard data |    ✅    |   ✅   |   ✅   |   ✅   |    ✅     |     ✅      |    ✅    |

## Clipboard

Clipboard data is represented by a `ClipboardContent` record containing a MIME type and its raw bytes. The API returns `FutureOr` values, so it can be used consistently with `await` on every platform.

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:lw_sysapi/lw_sysapi.dart';

Future<String?> copyAndReadText() async {
  final clipboard = await SysAPI.getClipboardManager();

  final copied = await clipboard.setContent((
    type: ClipboardMimeTypes.text,
    data: Uint8List.fromList(utf8.encode('Hello from lw_sysapi')),
  ));
  if (!copied) return null;

  final content = await clipboard.getContent(
    types: const [ClipboardMimeTypes.text],
  );
  if (content == null) return null;

  return utf8.decode(content.data);
}
```

Pass MIME types to `getContent` in preference order. When `types` is omitted, the manager checks the types in `ClipboardMimeTypes.defaultTypes`.

Binary data uses the same API:

```dart
Future<bool> copyPng(Uint8List pngBytes) async {
  final clipboard = await SysAPI.getClipboardManager();
  return clipboard.setContent((
    type: ClipboardMimeTypes.png,
    data: pngBytes,
  ));
}
```

`getContent` returns `null` and `setContent` returns `false` when the requested operation is unavailable or unsupported. Use `SysAPI.getClipboardManager(internal: true)` for an in-memory, process-local clipboard instead of the system clipboard.

## Information

This package is only available as git dependency and will be used in Linwood apps.
This package is not designed for public use. There will be breaking changes between commits.
