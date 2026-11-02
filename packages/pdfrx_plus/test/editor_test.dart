import 'dart:io';
import 'dart:typed_data';

import 'package:pdfrx_plus/pdfrx_plus.dart';
import 'package:pdfium_dart/pdfium_dart.dart' as f;
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    Pdfrx.pdfiumModulePath = Platform.environment['PDFIUM_TEST_MODULE_PATH'];
    await pdfrxInitialize();
  });

  Future<PdfDocument> create({double width = 200, double height = 200}) async {
    final doc = await PdfDocument.createNew(sourceName: 'test.pdf');
    addTearDown(doc.dispose);
    await doc.editor.addPage(width: width, height: height);
    return doc;
  }

  test('objects and Unicode comments survive encode and reopening', () async {
    final doc = await create();
    await doc.pages.first.addObjects([
      PdfDrawPath(
        PdfVectorPath()..addRect(10, 20, 30, 40),
        fill: const PdfRgba(255, 0, 0),
      ),
      const PdfDrawText(
        'searchable',
        transform: PdfAffineTransform.translation(20, 110),
      ),
    ]);
    await doc.pages.first.addAnnotation(
      PdfAnnotationSpec(
        type: PdfAnnotationType.text,
        bounds: const PdfRect(70, 90, 90, 70),
        content: 'Grüße 🦋',
        title: 'Author',
        id: 'note-1',
      ),
    );
    await doc.pages.first.addAnnotation(
      PdfAnnotationSpec(
        type: PdfAnnotationType.highlight,
        bounds: const PdfRect(20, 120, 90, 105),
        id: 'highlight-1',
        quadPoints: const [
          [
            PdfPoint(20, 120),
            PdfPoint(90, 120),
            PdfPoint(20, 105),
            PdfPoint(90, 105),
          ],
        ],
      ),
    );
    final bytes = await doc.encodePdf();
    final restored = await PdfDocument.openData(bytes);
    addTearDown(restored.dispose);
    final objects = await restored.pages.first.loadPageObjects();
    expect(objects.map((o) => o.type), containsAll([1, 2]));
    expect(
      (await restored.pages.first.loadText())!.fullText,
      contains('searchable'),
    );
    final annotations = await restored.pages.first.loadAnnotationDetails();
    final note = annotations.singleWhere((a) => a.id == 'note-1');
    expect(note.metadata.content, 'Grüße 🦋');
    expect(note.metadata.title, 'Author');
    expect(note.type, PdfAnnotationType.text);
    expect(
      annotations.singleWhere((a) => a.id == 'highlight-1').quadPoints.single,
      hasLength(4),
    );
  });

  test('a failed batch leaves earlier successful objects saveable and reloads the page', () async {
    final doc = await create();
    await expectLater(
      doc.pages.first.addObjects([
        PdfDrawPath(
          PdfVectorPath()..addRect(10, 10, 20, 20),
          fill: const PdfRgba.black(),
        ),
        const PdfRemoveObject(999),
      ]),
      throwsA(anything),
    );
    expect(await doc.pages.first.loadPageObjects(), hasLength(1));
    final reopened = await PdfDocument.openData(await doc.encodePdf());
    addTearDown(reopened.dispose);
    expect((await reopened.pages.first.loadPageObjects()).single.type, 2);
  });

  test(
    'updates and removes annotations without conflating them with links',
    () async {
      final doc = await create();
      await doc.pages.first.addAnnotation(
        PdfAnnotationSpec(
          type: PdfAnnotationType.text,
          bounds: const PdfRect(20, 40, 40, 20),
          content: 'before',
          id: 'note',
        ),
      );
      final note = (await doc.pages.first.loadAnnotationDetails()).single;
      await doc.editor.updateAnnotation(
        0,
        note.index,
        PdfAnnotationSpec(
          type: note.type,
          bounds: note.bounds,
          content: 'after',
          id: note.id,
        ),
      );
      expect(
        (await doc.pages.first.loadAnnotationDetails()).single.metadata.content,
        'after',
      );
      await doc.editor.removeAnnotation(0, 0);
      expect(await doc.pages.first.loadAnnotationDetails(), isEmpty);
    },
  );

  test(
    'placed pages remain vector/text content and copy comments at the offset',
    () async {
      final source = await create(width: 100, height: 80);
      await source.pages.first.addObjects([
        PdfDrawPath(
          PdfVectorPath()..addRect(10, 20, 20, 10),
          fill: const PdfRgba(255, 0, 0),
        ),
        const PdfDrawText(
          'original',
          fontSize: 10,
          transform: PdfAffineTransform.translation(10, 45),
        ),
      ]);
      await source.pages.first.addAnnotation(
        PdfAnnotationSpec(
          type: PdfAnnotationType.text,
          bounds: const PdfRect(50, 60, 65, 45),
          content: 'source comment',
          id: 'source-note',
        ),
      );
      final bytes = await source.encodePdf();
      final originalBytes = Uint8List.fromList(bytes);
      final target = await create();
      await target.pages.first.addObjects([
        PdfPlacePage(
          bytes,
          pageIndex: 0,
          transform: const PdfAffineTransform(1, 0, 0, -1, 30, 150),
        ),
      ]);
      final restored = await PdfDocument.openData(await target.encodePdf());
      addTearDown(restored.dispose);
      final placedObjects = await restored.pages.first.loadPageObjects();
      expect(placedObjects, isNotEmpty);
      expect(placedObjects.every((object) => object.type == 5), isTrue);
      expect(
        (await restored.pages.first.loadText())!.fullText,
        contains('original'),
      );
      final note = (await restored.pages.first.loadAnnotationDetails()).single;
      expect(note.bounds.left, 80);
      expect(note.bounds.top, 130);
      expect(note.metadata.content, 'source comment');
      // A second PDFium save can generate a different trailer ID. Check the
      // actual input buffer and source state rather than comparing two saves.
      expect(bytes, orderedEquals(originalBytes));
      expect(await source.pages.first.loadPageObjects(), hasLength(2));
      expect(
        (await source.pages.first.loadAnnotationDetails())
            .single
            .metadata
            .content,
        'source comment',
      );
      final image = await restored.pages.first.render();
      addTearDown(image!.dispose);
      final p = (105 * image.width + 50) * 4;
      // Native PDFium returns BGRA.
      expect(image.pixels[p + 2], greaterThan(240));
      expect(image.pixels[p + 1], lessThan(20));
    },
  );

  test('source CropBox and rotation are normalized once', () async {
    final source = await create(width: 100, height: 80);
    await source.pages.first.addObjects([
      PdfDrawPath(
        PdfVectorPath()..addRect(10, 20, 20, 10),
        fill: const PdfRgba(255, 0, 0),
      ),
    ]);
    await source.useNativeDocumentHandle((handle) {
      final api = f.getPdfium(modulePath: Pdfrx.pdfiumModulePath);
      final page = api.FPDF_LoadPage(f.FPDF_DOCUMENT.fromAddress(handle), 0);
      try {
        api.FPDFPage_SetCropBox(page, 5, 10, 95, 70);
        api.FPDFPage_SetRotation(page, 1);
      } finally {
        api.FPDF_ClosePage(page);
      }
    });
    await source.reloadPages(pageNumbersToReload: [1]);
    final geom = await source.pages.first.loadGeometry();
    expect(geom.width, 60);
    expect(geom.height, 90);
    final target = await create();
    await target.pages.first.addObjects([
      PdfPlacePage(
        await source.encodePdf(),
        pageIndex: 0,
        transform: const PdfAffineTransform(1, 0, 0, -1, 30, 150),
      ),
    ]);
    final image = await target.pages.first.render();
    addTearDown(image!.dispose);
    final p = (65 * image.width + 45) * 4;
    expect(image.pixels[p + 2], greaterThan(240));
    expect(image.pixels[p + 1], lessThan(20));
  });

  test('object transforms and removal persist', () async {
    final doc = await create();
    await doc.pages.first.addObjects([
      PdfDrawPath(
        PdfVectorPath()..addRect(0, 0, 10, 10),
        fill: const PdfRgba.black(),
      ),
    ]);
    await doc.pages.first.addObjects([
      const PdfTransformObject(0, PdfAffineTransform.translation(50, 60)),
    ]);
    expect((await doc.pages.first.loadPageObjects()).single.bounds.left, 50);
    await doc.pages.first.addObjects([const PdfRemoveObject(0)]);
    expect(await doc.pages.first.loadPageObjects(), isEmpty);
    await expectLater(
      doc.editor.apply(0, [const PdfRemoveObject(99)]),
      throwsA(anything),
    );
  });

  test('RGBA images keep straight alpha and survive encoding', () async {
    final doc = await create();
    await doc.pages.first.addObjects([
      PdfDrawImage(
        Uint8List.fromList([255, 0, 0, 128]),
        width: 1,
        height: 1,
        transform: const PdfAffineTransform(20, 0, 0, 20, 50, 50),
      ),
    ]);
    final restored = await PdfDocument.openData(await doc.encodePdf());
    addTearDown(restored.dispose);
    final image = await restored.pages.first.render();
    addTearDown(image!.dispose);
    final at = (140 * image.width + 60) * 4;
    expect(image.pixels[at + 2], greaterThan(245));
    expect(image.pixels[at + 1], closeTo(127, 3));
    expect((await restored.pages.first.loadPageObjects()).single.type, 3);
  });

  test(
    'existing annotation appearances retain their colors as vector content',
    () async {
      final source = await create(width: 100, height: 80);
      await source.pages.first.addAnnotation(
        PdfAnnotationSpec(
          type: PdfAnnotationType.highlight,
          bounds: const PdfRect(10, 60, 50, 40),
          id: 'blue',
          color: const PdfRgba(0, 0, 255),
          quadPoints: const [
            [
              PdfPoint(10, 60),
              PdfPoint(50, 60),
              PdfPoint(10, 40),
              PdfPoint(50, 40),
            ],
          ],
        ),
      );
      final originalImage = await source.pages.first.render();
      addTearDown(originalImage!.dispose);
      expect(
        (await source.pages.first.loadAnnotationDetails()).single.hasAppearance,
        isTrue,
      );
      final bytes = await source.encodePdf();
      final target = await create(width: 100, height: 80);
      await target.pages.first.addObjects([
        PdfPlacePage(
          bytes,
          pageIndex: 0,
          transform: const PdfAffineTransform(1, 0, 0, -1, 0, 80),
        ),
      ]);
      final image = await target.pages.first.render();
      addTearDown(image!.dispose);
      final at = (30 * image.width + 30) * 4;
      expect(
        image.pixels.sublist(at, at + 4),
        originalImage.pixels.sublist(at, at + 4),
      );
      final restored = await PdfDocument.openData(await target.encodePdf());
      addTearDown(restored.dispose);
      expect(
        (await restored.pages.first.loadAnnotationDetails()).single.id,
        'blue',
      );
      expect(
        (await restored.pages.first.loadPageObjects()).every(
          (o) => o.type == 5,
        ),
        isTrue,
      );
    },
  );
}
