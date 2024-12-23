import 'dart:io';

import 'package:archive/archive.dart';

Future<Archive> createReproducableArchive(
  Directory dir, {
  int lastModTime = 0,
}) async {
  final archive = Archive();
  Future<void> addDirectory(Directory dir, String prefix) async {
    final files = List.from(await dir.list().toList())
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
      if (file is File) {
        final filename = file.path.substring(dir.path.length + 1);
        final fileData = await file.readAsBytes();
        archive.addFile(
            ArchiveFile('$prefix/$filename', fileData.length, fileData)
              ..lastModTime = lastModTime);
      } else if (file is Directory) {
        await addDirectory(
            file, '$prefix/${file.path.substring(dir.path.length + 1)}');
      }
    }
  }

  await addDirectory(dir, '');
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
