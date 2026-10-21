// Compiled into the private cache so native hooks can use it on every host OS.
import 'dart:convert';
import 'dart:io';

import '../native.dart';

Future<void> main(List<String> arguments) async {
  final config =
      jsonDecode(
            File(
              '${File(Platform.resolvedExecutable).parent.path}/rustup.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final environment = {
    ...Platform.environment,
    ...(config['environment'] as Map).cast<String, String>(),
  };
  final targetIndex = arguments.indexOf('--target');
  final target = targetIndex >= 0 ? arguments[targetIndex + 1] : '';
  final outputIndex = arguments.indexOf('--target-dir');
  final output = outputIndex >= 0
      ? Directory(arguments[outputIndex + 1])
      : Directory(environment['CARGO_TARGET_DIR']!);
  environment.addAll(
    reproducibleEnvironment(
      sourceRoot: Uri.parse(config['source_root'] as String),
      prefix: config['prefix'] as String,
      outputDirectory: output.uri,
      windows:
          target.contains('windows-msvc') ||
          target.isEmpty && Platform.isWindows,
      environment: environment,
    ),
  );
  final process = await Process.start(
    config['executable'] as String,
    [
      ...arguments,
      if (arguments.length >= 4 &&
          arguments[0] == 'run' &&
          arguments[2] == 'cargo' &&
          arguments[3] == 'build' &&
          !arguments.contains('--locked'))
        '--locked',
    ],
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
