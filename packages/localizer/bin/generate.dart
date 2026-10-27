import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

/// Embeds Crowdin-friendly JSON resources into a Dart library for AOT exports.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'source',
      defaultsTo: 'l10n',
      help: 'Directory of locale JSON files.',
    )
    ..addOption('output', defaultsTo: 'lib/src/generated/messages.g.dart')
    ..addOption(
      'name',
      defaultsTo: 'createLocalizer',
      help: 'Generated factory name.',
    )
    ..addFlag(
      'check',
      negatable: false,
      help: 'Fail if generated output is stale.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final options = parser.parse(arguments);
    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }
    final source = Directory(options['source'] as String);
    final target = File(options['output'] as String);
    final name = options['name'] as String;
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      throw const FormatException('Invalid generated factory name');
    }
    final files =
        source
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final locales = <String, Map<String, String>>{};
    for (final file in files) {
      final locale = file.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.json$'),
        '',
      );
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      locales[locale] = decoded.map((key, value) {
        if (value is! String) {
          throw FormatException('Expected a string at $locale:$key');
        }
        return MapEntry(key, value);
      });
    }
    final english = locales['en'];
    if (english == null) {
      throw const FormatException('l10n/en.json is required');
    }
    Set<String> placeholders(String value) => RegExp(
      r'%(\d+)\$[a-z]',
    ).allMatches(value).map((match) => match.group(1)!).toSet();
    for (final locale in locales.entries) {
      for (final message in locale.value.entries) {
        final original = english[message.key];
        if (original == null) {
          throw FormatException('Unknown key ${locale.key}:${message.key}');
        }
        final expected = placeholders(original);
        final actual = placeholders(message.value);
        if (expected.length != actual.length || !expected.containsAll(actual)) {
          throw FormatException(
            'Placeholder mismatch at ${locale.key}:${message.key}',
          );
        }
      }
    }
    String literal(String value) => jsonEncode(value).replaceAll(r'$', r'\$');
    final output = StringBuffer()
      ..writeln('// @dart=3.8')
      ..writeln('// GENERATED CODE — edit the JSON files in l10n/ instead.')
      ..writeln("import 'dart:convert';")
      ..writeln("import 'package:localizer/localizer.dart';")
      ..writeln()
      ..writeln('const _bundled = <String, String>{');
    for (final locale in locales.entries) {
      output.writeln(
        '  ${literal(locale.key)}: ${literal(jsonEncode(locale.value))},',
      );
    }
    output
      ..writeln('};')
      ..writeln()
      ..writeln(
        '/// All resources are embedded; no runtime files are accessed.',
      )
      ..writeln('Localizer $name({bool Function(String key)? include}) {')
      ..writeln('  final localizer = Localizer();')
      ..writeln('  for (final locale in _bundled.entries) {')
      ..writeln(
        '    final messages = jsonDecode(locale.value) as Map<String, dynamic>;',
      )
      ..writeln('    localizer.loadMap(locale.key, {')
      ..writeln('      for (final message in messages.entries)')
      ..writeln(
        '        if (include == null || include(message.key)) message.key: message.value,',
      )
      ..writeln('    });')
      ..writeln('  }')
      ..writeln('  return localizer;')
      ..writeln('}');
    // Format through the SDK so --check is deterministic across regenerations.
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'localizer-l10n-',
    );
    final temporary = File('${temporaryDirectory.path}/messages.dart');
    try {
      temporary.writeAsStringSync(output.toString());
      final formatted = Process.runSync(Platform.resolvedExecutable, [
        '--suppress-analytics',
        'format',
        temporary.path,
      ]);
      if (formatted.exitCode != 0) {
        throw StateError(formatted.stderr.toString());
      }
      final generated = temporary.readAsStringSync();
      if (options['check'] as bool) {
        if (!target.existsSync() || target.readAsStringSync() != generated) {
          throw StateError(
            'Translations are stale. Run the generator without --check.',
          );
        }
      } else {
        target.parent.createSync(recursive: true);
        target.writeAsStringSync(generated);
      }
    } finally {
      temporaryDirectory.deleteSync(recursive: true);
    }
    stdout.writeln('Bundled ${locales.length} locales into ${target.path}');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
