import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

/// Use a source timestamp, never the time at which a build happens to run.
Future<int> sourceDateEpoch(Directory root, [String? override]) async {
  var value = override ?? Platform.environment['SOURCE_DATE_EPOCH'];
  if (value == null) {
    final result = await Process.run('git', [
      'log',
      '-1',
      '--format=%ct',
    ], workingDirectory: root.path);
    if (result.exitCode != 0) {
      throw StateError(
        'Set SOURCE_DATE_EPOCH when building without Git history.',
      );
    }
    value = result.stdout.toString().trim();
  }
  final epoch = int.tryParse(value);
  if (epoch == null || epoch < 0 || epoch > 0x7fffffff) {
    throw FormatException(
      'SOURCE_DATE_EPOCH must be Unix seconds (0..2147483647).',
    );
  }
  return epoch;
}

/// Hash every byte and record links and permissions without following symlinks.
/// Filesystem timestamps are packaging inputs, not part of a directory's payload.
Future<Map<String, dynamic>> artifactManifest(FileSystemEntity artifact) async {
  final entries = <String, dynamic>{};
  Future<void> visit(String path, String name) async {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      entries[name] = {'type': 'link', 'target': Link(path).targetSync()};
    } else if (type == FileSystemEntityType.file) {
      final file = File(path);
      entries[name] = {
        'type': 'file',
        'size': file.lengthSync(),
        'sha256': (await sha256.bind(file.openRead()).first).toString(),
        if (!Platform.isWindows) 'mode': file.statSync().mode & 0x1ff,
      };
    } else if (type == FileSystemEntityType.directory) {
      entries[name] = {
        'type': 'directory',
        if (!Platform.isWindows)
          'mode': Directory(path).statSync().mode & 0x1ff,
      };
      final children = Directory(path).listSync(followLinks: false)
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final child in children) {
        final leaf = child.uri.pathSegments.where((s) => s.isNotEmpty).last;
        await visit(child.path, name == '.' ? leaf : '$name/$leaf');
      }
    } else {
      throw StateError('Missing or unsupported artifact entry: $path');
    }
  }

  await visit(artifact.path, '.');
  return entries;
}

List<String> manifestDifferences(Map first, Map second) {
  final names = {
    ...first.keys.cast<String>(),
    ...second.keys.cast<String>(),
  }.toList()..sort();
  return [
    for (final name in names)
      if (jsonEncode(first[name]) != jsonEncode(second[name])) name,
  ];
}

/// Stable ZIP order, UTC timestamp, permissions and symlink payloads. No signing
/// data or binary metadata is removed or rewritten.
Future<void> reproducibleZip(
  Directory source,
  File output,
  int epoch, {
  String? prefix,
}) => _archive(source, output, epoch, prefix: prefix, tar: false);

Future<void> reproducibleTarGz(
  Directory source,
  File output,
  int epoch, {
  String? prefix,
}) => _archive(source, output, epoch, prefix: prefix, tar: true);

Future<void> _archive(
  Directory source,
  File output,
  int epoch, {
  String? prefix,
  required bool tar,
}) async {
  if (prefix != null &&
      prefix
          .split('/')
          .any(
            (part) =>
                part.isEmpty ||
                part == '.' ||
                part == '..' ||
                part.contains(RegExp(r'[\\:]')),
          )) {
    throw ArgumentError(
      'The archive prefix must be a relative directory path.',
    );
  }
  final root = source.resolveSymbolicLinksSync();
  output.parent.createSync(recursive: true);
  String normalized(String path) {
    final slashes = path.replaceAll('\\', '/');
    return Platform.isWindows ? slashes.toLowerCase() : slashes;
  }

  final destination = normalized(
    '${output.parent.resolveSymbolicLinksSync()}/${output.uri.pathSegments.last}',
  );
  final sourcePath = normalized(root);
  if (destination == sourcePath || destination.startsWith('$sourcePath/')) {
    throw ArgumentError(
      'The archive output must be outside the input directory.',
    );
  }
  final manifest = await artifactManifest(source);
  final archive = Archive();
  if (prefix != null) {
    archive.add(
      ArchiveFile.directory(prefix)
        ..mode = tar ? 0x1ed : 0x41ed
        ..creationTime = epoch
        ..lastModTime = epoch,
    );
  }
  final names = manifest.keys.where((name) => name != '.').toList()..sort();
  for (final name in names) {
    final metadata = manifest[name] as Map;
    final path = '$root/$name';
    final archiveName = prefix == null ? name : '$prefix/$name';
    final entry = switch (metadata['type']) {
      'directory' => ArchiveFile.directory(
        archiveName,
      )..mode = tar ? 0x1ed : 0x41ed,
      'link' when tar => ArchiveFile.symlink(
        archiveName,
        metadata['target'] as String,
      )..mode = 0x1ff,
      // ZIP stores a symlink as its target text with the Unix symlink mode.
      'link' => ArchiveFile.string(
        archiveName,
        metadata['target'] as String,
      )..mode = 0xa1ff,
      _ => ArchiveFile.stream(
        archiveName,
        InputFileStream(path),
      )..mode = (tar ? 0 : 0x8000) | (metadata['mode'] as int? ?? 0x1a4),
    };
    archive.add(
      entry
        ..creationTime = epoch
        ..lastModTime = epoch,
    );
  }
  if (tar) {
    final temporary = await Directory.systemTemp.createTemp(
      'generate-leap-tar-',
    );
    final contents = File('${temporary.path}/payload.tar');
    final stream = OutputFileStream(contents.path);
    try {
      TarEncoder().encodeStream(archive, stream);
      await stream.close();
      await contents
          .openRead()
          .transform(GZipCodec(level: 9).encoder)
          .pipe(output.openWrite());
    } finally {
      await stream.close();
      await archive.clear();
      if (await contents.exists()) await contents.delete();
      await temporary.delete();
    }
    return;
  }
  final stream = OutputFileStream(output.path);
  try {
    ZipEncoder().encodeStream(
      archive,
      stream,
      level: 9,
      // ZIP's DOS timestamp has no timezone and cannot represent pre-1980 dates.
      modified:
          DateTime.fromMillisecondsSinceEpoch(
            epoch * 1000,
            isUtc: true,
          ).isBefore(DateTime.utc(1980))
          ? DateTime.utc(1980)
          : DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true),
      autoClose: true,
    );
  } finally {
    await stream.close();
    await archive.clear();
  }
  await _unixZipMetadata(output);
}

Future<void> _unixZipMetadata(File output) async {
  final file = output.openSync(mode: FileMode.append);
  try {
    final length = file.lengthSync();
    final tailLength = length < 65557 ? length : 65557;
    file.setPositionSync(length - tailLength);
    final tail = ByteData.sublistView(file.readSync(tailLength));
    var end = -1;
    for (var i = tailLength - 22; i >= 0; i--) {
      if (tail.getUint32(i, Endian.little) == 0x06054b50 &&
          i + 22 + tail.getUint16(i + 20, Endian.little) == tailLength) {
        end = i;
        break;
      }
    }
    if (end < 0) throw const FormatException('Missing ZIP directory.');
    final count = tail.getUint16(end + 10, Endian.little);
    var offset = tail.getUint32(end + 16, Endian.little);
    if (count == 0xffff || offset == 0xffffffff) {
      throw const FormatException(
        'ZIP64 is unsupported; use tar.gz for large bundles.',
      );
    }
    for (var i = 0; i < count; i++) {
      file.setPositionSync(offset);
      final header = ByteData.sublistView(file.readSync(46));
      if (header.lengthInBytes != 46 ||
          header.getUint32(0, Endian.little) != 0x02014b50) {
        throw const FormatException('Invalid ZIP directory entry.');
      }
      file.setPositionSync(offset + 5);
      file.writeByteSync(3); // Unix creator OS; retain the encoder version.
      offset +=
          46 +
          header.getUint16(28, Endian.little) +
          header.getUint16(30, Endian.little) +
          header.getUint16(32, Endian.little);
    }
  } finally {
    file.closeSync();
  }
}
