import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:test/test.dart';

void main() {
  group('translation generation', () {
    late Directory directory;
    late String generator;
    late String packages;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('localizer-resources-');
      final library = (await Isolate.resolvePackageUri(
        Uri.parse('package:localizer/localizer.dart'),
      ))!;
      generator = library.resolve('../bin/generate.dart').toFilePath();
      packages = (await Isolate.packageConfig)!.toFilePath();
      await Directory('${directory.path}/l10n').create();
    });
    tearDown(() => directory.delete(recursive: true));

    Future<void> writeLocale(String locale, Map<String, String> messages) =>
        File(
          '${directory.path}/l10n/$locale.json',
        ).writeAsString(jsonEncode(messages));
    Future<ProcessResult> generate({bool check = false}) =>
        Process.run(Platform.resolvedExecutable, [
          '--packages=$packages',
          generator,
          '--source',
          '${directory.path}/l10n',
          '--output',
          '${directory.path}/bundled.dart',
          '--name',
          'createTestLocalizer',
          if (check) '--check',
        ]);

    test('embeds locales and detects stale generated output', () async {
      await writeLocale('en', {'hello': r'Hello %1$s'});
      await writeLocale('de', {'hello': r'Hallo %1$s'});
      expect((await generate()).exitCode, 0);
      expect((await generate(check: true)).exitCode, 0);
      await writeLocale('de', {'hello': r'Guten Tag %1$s'});
      final stale = await generate(check: true);
      expect(stale.exitCode, isNonZero);
      expect(stale.stderr.toString(), contains('stale'));
      expect((await generate()).exitCode, 0);
    });

    test('rejects translations that lose parameters', () async {
      await writeLocale('en', {'hello': r'Hello %1$s'});
      await writeLocale('de', {'hello': 'Hallo'});
      final result = await generate();
      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('Placeholder mismatch'));
      expect(File('${directory.path}/bundled.dart').existsSync(), isFalse);
    });
  });
}
