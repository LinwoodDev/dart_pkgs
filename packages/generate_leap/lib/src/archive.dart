import 'dart:io';

import 'package:archive/archive.dart';

Future<Archive> createReproducableArchive(
  Directory dir, {
  int lastModTime = 0,
}) async {
  final archive = Archive();
  Future<void> addDirectory(Directory current) async {
    final files = List<FileSystemEntity>.from(await current.list().toList())
      ..sort((a, b) {
        if (a is Directory && b is File) {
          return -1;
        } else if (a is File && b is Directory) {
          return 1;
        } else {
          return a.path.compareTo(b.path);
        }
      });
    for (final file in files) {
      final name = file.path.substring(dir.path.length + 1);
      if (file is File) {
        final fileData = await file.readAsBytes();
        archive.addFile(
            ArchiveFile.bytes(name, fileData)..lastModTime = lastModTime);
      } else if (file is Directory) {
        archive.addFile(ArchiveFile.directory(name)..lastModTime = lastModTime);
        await addDirectory(file);
      }
    }
  }

  await addDirectory(dir);
  return archive;
}

Future<void> zipReproducable(
  Directory dir,
  String path, {
  int lastModTime = 0,
}) async {
  final encoder = ZipEncoder();
  final zip = encoder
      .encode(await createReproducableArchive(dir, lastModTime: lastModTime));
  final file = File(path);
  await file.writeAsBytes(zip);
}
