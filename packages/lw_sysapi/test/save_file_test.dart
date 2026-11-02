import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('linwood.dev/lw_sysapi');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('native_file_dialogs_');
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });

  test(
    'exports infer, override, or omit extensions with named defaults',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      for (final (name, override, expected, extension) in [
        ('drawing.bfly', null, 'drawing.bfly', 'bfly'),
        ('drawing.txt', '.bfly', 'drawing.txt.bfly', 'bfly'),
        ('README', null, 'README', null),
      ]) {
        MethodCall? request;
        final destination = File('${temp.path}/$expected');
        messenger.setMockMethodCallHandler(channel, (call) async {
          request = call;
          return destination.path;
        });

        await exportFile(bytes: bytes, fileName: name, fileExtension: override);

        expect(request!.method, 'getSavePath');
        expect(request!.arguments, containsPair('name', expected));
        expect(request!.arguments, containsPair('extension', extension));
        expect(
          request!.arguments,
          containsPair('mime', 'application/octet-stream'),
        );
        expect(await destination.readAsBytes(), bytes);
      }
    },
  );

  test('invalid native save suffix cannot overwrite either target', () async {
    final wrong = File('${temp.path}/drawing.txt');
    final correct = File('${temp.path}/drawing.txt.bfly');
    await wrong.writeAsBytes([8]);
    await correct.writeAsBytes([9]);
    messenger.setMockMethodCallHandler(channel, (_) async => wrong.path);

    await expectLater(
      SystemFileDialogs.saveFile(
        fileName: 'drawing',
        fileExtension: 'bfly',
        bytes: Uint8List.fromList([1]),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await wrong.readAsBytes(), [8]);
    expect(await correct.readAsBytes(), [9]);
  });

  test(
    'cancelled dialogs return empty results without creating files',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      expect(await SystemFileDialogs.pickFiles(extensions: ['bfly']), isEmpty);
      expect(await SystemFileDialogs.pickFile(extensions: ['tbfly']), isNull);
      expect(await SystemFileDialogs.getDirectoryPath(), isNull);
      expect(
        await SystemFileDialogs.saveFile(
          fileName: 'cancelled',
          fileExtension: 'bfly',
          bytes: Uint8List(0),
        ),
        false,
      );
      expect(calls[0].arguments, containsPair('multiple', true));
      expect(calls[1].arguments, containsPair('multiple', false));
      expect(await temp.list().toList(), isEmpty);
    },
  );

  test('multiple custom files preserve names and are read lazily', () async {
    final first = File('${temp.path}/first.bfly');
    final second = File('${temp.path}/second.tbfly');
    await first.writeAsBytes([1]);
    await second.writeAsBytes([2]);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'readFile') {
        return File((call.arguments as Map)['path'] as String).readAsBytes();
      }
      expect(call.method, 'pickFiles');
      expect(call.arguments, containsPair('extensions', ['bfly', 'tbfly']));
      return [
        {'name': 'first.bfly', 'path': first.path},
        {'name': 'second.tbfly', 'path': second.path},
      ];
    });

    final files = await SystemFileDialogs.pickFiles(
      extensions: ['bfly', 'tbfly'],
    );
    await first.writeAsBytes([3]);
    expect(files.map((file) => file.name), ['first.bfly', 'second.tbfly']);
    expect(files.first.extension, 'bfly');
    expect(await files.first.readAsBytes(), [3]);
    expect(await files.last.readAsBytes(), [2]);
  });

  test('directory grants preserve document-provider URIs', () async {
    const uri = 'content://provider/tree/primary%3Anotes';
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickDirectory');
      return uri;
    });
    expect(await SystemFileDialogs.getDirectoryPath(), uri);
  });
}
