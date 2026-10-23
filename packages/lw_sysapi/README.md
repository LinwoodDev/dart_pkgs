# lw_sysapi

> Utility methods to access system information

## Features

|                Method | Description                         | Windows | Linux | macOS |  iOS  | Web (JS) | Web (WASM) | Android |
| --------------------: | :---------------------------------- | :-----: | :---: | :---: | :---: | :------: | :--------: | :-----: |
|            `getFonts` | Get all system fonts                |    ✅    |   ✅   |   ❌   |   ❌   |    ✅     |     ✅      |    ❌    |
| `getClipboardManager` | Read and write typed clipboard data |    ✅    |   ✅   |   ✅   |   ✅   |    ✅     |     ✅      |    ✅    |
|   `getDisplayMetrics` | Get physical display pixel density |    ✅    |   ✅   |   ✅   |   ❌   |    ❌     |     ❌      |    ✅    |

## Physical display size

`SysAPI.getDisplayMetrics()` reads the physical X/Y pixel density of the display
containing the plugin's registered app view. The returned `DisplayMetrics` can
convert canvas units to displayed millimeters and back. A canvas unit is one
Flutter logical pixel before camera zoom. Supply the current view's
device pixel ratio from `MediaQuery.devicePixelRatioOf(context)` or
`View.of(context).devicePixelRatio` separately.

```dart
import 'dart:ui';
import 'package:lw_sysapi/lw_sysapi.dart';

Future<Size?> a4SizeInCanvasUnits(double devicePixelRatio, double zoom) async {
  final metrics = await SysAPI.getDisplayMetrics();
  return metrics?.millimetersToCanvasUnits(
    const Size(210, 297),
    devicePixelRatio: devicePixelRatio,
    zoom: zoom,
  );
}
```

For an already displayed canvas, convert its document size with
`metrics.canvasUnitsToMillimeters(size, devicePixelRatio: currentRatio, zoom: canvasZoom)`.
Zoom is a factor: `1` means 100%, `2` means 200%.
This API does not assign units to document coordinates or change PDF units.

Android uses the activity's `DisplayMetrics.xdpi/ydpi`; Linux uses the app view's
GDK monitor geometry, scale and millimeter dimensions; macOS uses the app view's
`NSScreen` and Core Graphics millimeter dimensions; Windows uses the app view's
monitor and `MDT_RAW_DPI`, excluding the desktop UI scaling preference.

Physical values are reported by the OS/hardware and may be rounded or inaccurate.
The API returns `null` if valid physical metrics are unavailable. iOS and Web do
not expose physical pixel density through their standard display APIs, so they
return `null`; there is no nominal 96/160-DPI fallback or device-model lookup.

Query again when the view moves to another monitor or display metrics change.
`displayId` is a native, session-local identifier, not Flutter's `Display.id`.


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

## Drag and drop

`SystemDropTarget` receives external files, browser images, links and text on
Android, iOS, Linux, macOS, Windows and Web. It uses Flutter hit testing: the
innermost enabled target receives the drop, while opaque overlays and modal
routes block targets behind them. Positions are Flutter logical pixels.

```dart
SystemDropTarget(
  showFeedback: true,
  onDrop: (details) async {
    final result = await details.readContents(); // safeMode: true by default
    for (final item in result.contents) {
      final ClipboardContent content = item.content;
      // Feed the same MIME type and bytes into your clipboard/paste importer.
      importContent(content.type, content.data, name: item.name,
          position: details.localPosition);
    }
    // Reading one item may fail while the rest of the batch succeeds.
    for (final error in result.errors) {
      reportError(error);
    }
  },
  onError: (error, stack) => reportError(error),
  child: canvas,
)
```

`SystemDropItem` exposes a file URI or alternative `ClipboardContent`
representations. `readContents()` resolves file bytes, HTML image sources, data
URLs and HTTP(S) URLs without reading or writing the system clipboard. Actual
files/image bytes are preferred over alternate browser link representations.
`NamedClipboardContent` preserves file names separately from the shared MIME
record. Unsupported URI schemes and download failures are returned in `errors`.
Safe mode is enabled by default and blocks HTTP(S) requests. The host can opt
in to remote reads with `details.readContents(safeMode: false)`. Local files and
supplied bytes do not need this opt-in. Remote reads still reject credentials,
IP literals, local host names, nonstandard ports and redirects. On native
platforms, resolved DNS addresses must be public and connections use the exact
validated IP to prevent DNS rebinding; custom injected HTTP clients are
responsible for equivalent transport-level checks. Hidden local-file references
inside HTML and network file shares are always rejected.

Each item is limited to 32 MiB, and URI reads time out after 30 seconds; callers
can configure `maxBytes` and `timeout`. HTTP downloads stream under the byte
limit and are aborted on timeout. HTTP requests on Web remain subject to the
source server's CORS policy.

`enabled: false` rejects drops. `showFeedback` adds a hover border and a loading
indicator. Async `onDrop` handlers run once at a time per target. Use `onError`
to handle callback failures; otherwise they are reported through `FlutterError`.
Native clipboard and drop channels are separate and can be used concurrently.

## Information

This package is only available as git dependency and will be used in Linwood apps.
This package is not designed for public use. There will be breaking changes between commits.
