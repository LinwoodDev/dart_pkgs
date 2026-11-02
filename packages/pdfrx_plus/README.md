# pdfrx_plus

PDF object editing, annotation data and page composition on existing **pdfrx**
documents. Uses pdfrx's PDFium runtime; no dependency on the unrelated `pdf`
package, no second PDF parser and no additional PDFium binary.

## Initialization

Flutter (native and web):

```dart
import 'package:pdfrx/pdfrx.dart' show pdfrxFlutterInitialize;
import 'package:pdfrx_plus/pdfrx_plus.dart';

configurePdfrxPlus(); // before pdfrx initializes its Web worker
await pdfrxFlutterInitialize();
await initializePdfrxPlus(); // before opening Web documents
```

Dart native: call `pdfrxInitialize()` as usual. PDFium is required; Apple's
optional PDFKit backend does not provide these editing operations.

The caller owns documents and must await edits before disposing them. Reads and
edits on a document are serialized. Existing pdfrx rendering, text extraction,
font configuration, saving and page change notifications remain available.

## Read annotations and edit objects

```dart
final document = await PdfDocument.openData(bytes);
try {
  final page = document.pages.first;
  final annotations = await page.loadAnnotationDetails();
  for (final annotation in annotations) {
    print('${annotation.type}: ${annotation.metadata.content}');
  }
  await page.addObjects([
    PdfDrawPath(PdfVectorPath()..addRect(10, 20, 80, 40),
      stroke: const PdfRgba.black(), strokeWidth: 2),
    const PdfDrawText('Searchable text', fontSize: 12,
      transform: PdfAffineTransform.translation(20, 90)),
  ]);
  await page.addAnnotation(PdfAnnotationSpec(
    type: PdfAnnotationType.text,
    bounds: const PdfRect(20, 120, 40, 100),
    content: 'A comment', title: 'Author',
  ));
  final saved = await document.encodePdf();
} finally {
  await document.dispose();
}
```

Reads return immutable data snapshots without native annotation/object handles.
Metadata includes IDs, contents, author, subject, dates, flags, URI links,
reply/popup IDs, text-markup quads, ink strokes and appearance/color availability.
Object snapshots include type, bounds and transformation matrix. Indices are
zero based and refer to the current page state; reload them after removal.

Writing supports text notes, URI links, free text, squares, circles, highlight,
underline, squiggly, strikeout and ink. Unsupported subtypes fail explicitly.
`updateAnnotation(..., preserveAppearance: true)` keeps original appearance and
color when editing comment metadata. Changing an existing markup's quad count
requires replacement. Null metadata fields leave existing values intact; use an
empty string to clear a string. Reading is broader than writing.

Paths support lines, cubic curves, exact quadratic conversion, fills, strokes,
dashes, configurable line caps/joins, alpha and PDF blend modes. Images accept straight RGBA pixels. Text uses
a standard PDF font or supplied font bytes; callers are responsible for glyph
coverage and shaping/layout. Embedded font resources are reused within an edit
batch. `PdfDrawText.strokeWidth` can add a vector outline for synthetic bold. `PdfTransformObject` and `PdfRemoveObject` operate
on existing top-level objects. A batch is **not transactional**: on failure,
earlier successful commands can remain applied. For atomic export, edit an
owned document copy and discard it on error.

## Preserve and place a source PDF page

```dart
final output = await PdfDocument.createNew(sourceName: 'export.pdf');
try {
  await output.editor.addPage(width: 600, height: 900);
  await output.pages.first.addObjects([
    PdfPlacePage(sourceBytes, pageIndex: 0,
      transform: const PdfAffineTransform(1, 0, 0, -1, 25, 850)),
    // Add Butterfly paths or other objects here, in painting order.
  ]);
  final exported = await output.encodePdf();
} finally {
  await output.dispose();
}
```

Object/annotation coordinates use PDF points, bottom left origin, Y upwards.
`PdfRect` arguments are **left, top, right, bottom**. `PdfPlacePage` is the
exception: its input coordinate space is the **visible source page**, top left
origin, Y downwards. Its matrix maps that space into the destination PDF page.
`loadGeometry().toTopLeft` maps raw PDF coordinates, accounting for CropBox
offsets and all four page rotations. Matrix multiplication applies the right
operand first. Negative scaling, offsets, rotation and shear are supported.

Source bytes are never modified. Original page content is imported as a Form
XObject, preserving text, vectors, images and their resources. Page bounds clip
the result. Annotations are copied by default; set `copyAnnotations: false` to
exclude them. Original appearance streams are preserved in an additional vector
form, produced from a **disposable clone**, with semantic annotations retained
without a second painted appearance. The original source page is not flattened.

Unsupported annotation copying (including widgets, stamps, reply threads and
internal document destinations) throws instead of silently dropping metadata.
PDFium appearance flattening preserves the visible appearance; it does not
preserve every interactive behavior or separate screen/print appearance policy.
For these documents callers can explicitly choose a raster fallback or exclude
annotations. Editing encrypted/signed documents does not preserve signatures.

## Web compatibility

The Web backend currently targets **pdfrx 2.6.x / pdfrx_engine 0.6.x** and is
tested with pdfrx 2.6.5. It extends the existing worker with a small, versioned
JavaScript addon and imports the original pdfrx client/worker/WASM assets. It
does not copy the upstream implementation or import private Dart classes.

The upstream worker's `functions`, `disposers` and communicator are internal
interfaces. This adapter validates their presence and required PDFium exports,
but pdfrx upgrades must run the browser and WASM compatibility tests. A public
upstream worker-extension API would remove this coupling. Configure custom
upstream assets with `configurePdfrxPlus(wasmModulesUrl: ...)`. Assets and Blob
workers must be permitted by the application's CSP, as with pdfrx itself.

## Tests

Native (set an installed PDFium library path):

```sh
PDFIUM_TEST_MODULE_PATH=/path/to/libpdfium.so dart test
```

Real upstream Web worker and WASM, without a browser:

```sh
node test/web_worker_test.mjs /path/to/pdfrx-2.6.5/assets
```

Butterfly's `test/integration/pdf_build_smoke.dart` additionally exercises the
actual Flutter Web initialization, original pdfrx document classes, JS interop,
editing, saving and reopening in a browser. Run it with `flutter run -d chrome
--target test/integration/pdf_build_smoke.dart` from Butterfly's `app` directory.
