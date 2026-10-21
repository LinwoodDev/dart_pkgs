import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

typedef Json = Map<String, dynamic>;

/// Files and subprocesses for any build system. No Flutter or Rust is required.
class BuildContext {
  final Directory root;
  late final Directory cache;

  BuildContext({Directory? root}) : root = root ?? Directory.current;

  Directory get workingDirectory => root;
  File file(String path) => File('${root.path}/$path');
  File cached(String path) => File('${cache.path}/$path');

  Future<String> command(
    String executable,
    List<String> arguments,
    Map<String, String> environment, {
    bool capture = false,
  }) async {
    stdout.writeln('+ ${[executable, ...arguments].map(_quote).join(' ')}');
    if (capture) {
      final result = await Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory.path,
        environment: environment,
        runInShell: Platform.isWindows && executable.endsWith('.bat'),
      );
      if (result.exitCode == 0) return result.stdout as String;
      stderr.write(result.stderr);
      throw ProcessException(executable, arguments, '', result.exitCode);
    }
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory.path,
      environment: environment,
      runInShell: Platform.isWindows && executable.endsWith('.bat'),
      mode: ProcessStartMode.inheritStdio,
    );
    final status = await process.exitCode;
    if (status != 0) {
      throw ProcessException(executable, arguments, '', status);
    }
    return '';
  }
}

Json readJson(File file) => jsonDecode(file.readAsStringSync()) as Json;

void writeIfChanged(File file, String content) {
  if (file.existsSync() && file.readAsStringSync() == content) return;
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void writeJson(File file, Json value) => writeIfChanged(
  file,
  '${const JsonEncoder.withIndent('  ').convert(value)}\n',
);

Future<String> digest(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";

/// Save explicitly selected downloaded inputs, never compiled build outputs.
Future<Map<String, String>> cacheDownloads(
  Directory root,
  Directory cache,
  Iterable<File> inputs,
) async {
  final result = <String, String>{};
  final prefix = root.absolute.uri.toString();
  for (final input in inputs) {
    final uri = input.absolute.uri.toString();
    if (!uri.startsWith(prefix)) {
      throw ArgumentError('Download must be inside the input root.');
    }
    final relative = Uri.decodeFull(uri.substring(prefix.length));
    if (!_relativePath(relative) ||
        FileSystemEntity.typeSync(input.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw ArgumentError('Expected a regular downloaded input: ${input.path}');
    }
    final hash = await digest(input);
    await cache.create(recursive: true);
    await input.copy('${cache.path}/$hash');
    result[relative] = hash;
  }
  return result;
}

/// Restore inputs only after checking their stored content hashes.
Future<void> restoreDownloads(
  Directory root,
  Directory cache,
  Map<String, dynamic> entries,
) async {
  for (final entry in entries.entries) {
    final hash = entry.value;
    if (!_relativePath(entry.key) ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw StateError('Invalid downloaded input record. Run prepare again.');
    }
    final source = File('${cache.path}/$hash');
    if (!await source.exists() || await digest(source) != hash) {
      throw StateError(
        'Downloaded input changed or is missing. Run prepare again.',
      );
    }
    final target = File('${root.path}/${entry.key}');
    await target.parent.create(recursive: true);
    await source.copy(target.path);
  }
}

bool _relativePath(String path) =>
    !path.contains(RegExp(r'[\\:]')) &&
    path
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');
