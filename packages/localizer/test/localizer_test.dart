import 'dart:io';

import 'package:localizer/localizer.dart';
import 'package:test/test.dart';

void main() {
  group('Localizer load', () {
    setUp(() {
      // Generate locale files
      File("generated/en.json").writeAsStringSync(
          '{"hello-world": "Hello world!", "hello": "Hello %s"}');
      File("generated/es.json").writeAsStringSync(
          '{"hello-world": "Hola mundo!", "hello": "Hola %s"}');
      File("generated/fr.json").writeAsStringSync(
          '{"hello-world": "Bonjour le monde!", "hello": "Bonjour %s"}');
      File("generated/de.json").writeAsStringSync(
          '{"hello-world": "Hallo Welt!", "hello": "Hallo %s"}');
    });

    test('Load directory', () async {
      final localizer = Localizer();
      await localizer.loadDirectory('generated');
      expect(localizer.supportedLocales,
          unorderedEquals(["en", "es", "fr", "de"]));
    });
    test('Load single file', () async {
      final localizer = Localizer();
      await localizer.loadFile('generated/en.json');
      expect(localizer.supportedLocales, unorderedEquals(["en"]));
    });
    test('Get value of key', () async {
      final localizer = Localizer();
      await localizer.loadDirectory('generated');
      expect(localizer.get("en", "hello-world"), "Hello world!");
    });
  });
}
