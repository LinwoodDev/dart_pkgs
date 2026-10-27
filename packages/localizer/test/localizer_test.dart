import 'dart:io';

import 'package:localizer/localizer.dart';
import 'package:test/test.dart';

void main() {
  group('Localizer load', () {
    late Directory generatedDirectory;

    setUp(() {
      generatedDirectory = Directory.systemTemp.createTempSync(
        'localizer-test-',
      );

      // Generate locale files
      File("${generatedDirectory.path}/en.json").writeAsStringSync(
        '{"hello-world": "Hello world!", "hello": "Hello %s"}',
      );
      File(
        "${generatedDirectory.path}/es.json",
      ).writeAsStringSync('{"hello-world": "Hola mundo!", "hello": "Hola %s"}');
      File("${generatedDirectory.path}/fr.json").writeAsStringSync(
        '{"hello-world": "Bonjour le monde!", "hello": "Bonjour %s"}',
      );
      File("${generatedDirectory.path}/de.json").writeAsStringSync(
        '{"hello-world": "Hallo Welt!", "hello": "Hallo %s"}',
      );
    });

    tearDown(() {
      if (generatedDirectory.existsSync()) {
        generatedDirectory.deleteSync(recursive: true);
      }
    });

    test('Load directory', () async {
      final localizer = Localizer();
      await localizer.loadDirectory(generatedDirectory.path);
      expect(
        localizer.supportedLocales,
        unorderedEquals(["en", "es", "fr", "de"]),
      );
    });
    test('Load single file', () async {
      final localizer = Localizer();
      await localizer.loadFile('${generatedDirectory.path}/en.json');
      expect(localizer.supportedLocales, unorderedEquals(["en"]));
    });
    test('Get value of key', () async {
      final localizer = Localizer();
      await localizer.loadDirectory(generatedDirectory.path);
      expect(localizer.get("en", "hello-world"), "Hello world!");
    });
  });
}
