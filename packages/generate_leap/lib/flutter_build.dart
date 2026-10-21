import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'build.dart';
export 'build.dart';
import 'reproducible.dart';
import 'native.dart';

const _flutterFlags = ['--no-version-check', '--suppress-analytics'];
const _targets = {
  'android-arm': 'armv7-linux-androideabi',
  'android-arm64': 'aarch64-linux-android',
  'android-x64': 'x86_64-linux-android',
  'linux-x64': 'x86_64-unknown-linux-gnu',
  'linux-arm64': 'aarch64-unknown-linux-gnu',
  'windows-x64': 'x86_64-pc-windows-msvc',
  'windows-arm64': 'aarch64-pc-windows-msvc',
  'macos-x64': 'x86_64-apple-darwin',
  'macos-arm64': 'aarch64-apple-darwin',
  'ios-arm64': 'aarch64-apple-ios',
  'web': 'wasm32-unknown-unknown',
};

const _platforms = [
  'android',
  'linux',
  'windows',
  'macos',
  'ios',
  'web',
  'server',
];

/// Run prepare, build or verify using project-specific build steps.
Future<void> runFlutterBuild(
  List<String> arguments,
  FlutterBuild Function(ArgResults) create, {
  void Function(ArgParser)? configure,
}) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addOption(
      'platform',
      allowed: _platforms,
      help: 'Defaults to the host OS.',
    )
    ..addOption('cache-dir', help: 'Defaults to .offline-build/<platform>.')
    ..addOption('flutter', help: 'Flutter executable (defaults to PATH).')
    ..addOption(
      'source-date-epoch',
      help: 'Defaults to SOURCE_DATE_EPOCH or the Git commit timestamp.',
    )
    ..addFlag(
      'unsigned',
      negatable: false,
      help:
          'Prepare unsigned Android/macOS artifacts for independent comparison.',
    )
    ..addOption('flavor')
    ..addMultiOption(
      'dart-define',
      splitCommas: false,
      help: 'Additional compile-time values, remembered during preparation.',
    )
    ..addFlag('analyze-size', negatable: false)
    ..addOption('code-size-directory')
    ..addOption(
      'target-platform',
      help: 'Android ABIs or a Linux target, e.g. linux-arm64.',
    );
  configure?.call(parser);
  try {
    final options = parser.parse(arguments);
    if (options.flag('help')) {
      stdout.writeln(
        'Usage: dart tools/build_offline.dart <prepare|build|verify> [options]\n'
        '\n${parser.usage}',
      );
      return;
    }
    if (options.rest.length != 1 ||
        !['prepare', 'build', 'verify'].contains(options.rest.single)) {
      throw const FormatException(
        'Choose a command: prepare, build or verify.',
      );
    }
    await create(options).run();
  } catch (error) {
    stderr.writeln('Offline build: $error');
    exitCode = 1;
  }
}

class FlutterBuild extends BuildContext {
  static const flutterFlags = _flutterFlags;
  final ArgResults options;
  final String name;
  late final String flutter;
  late final String platform;
  late final List<String> dartDefines;
  late final int epoch;
  late final bool unsigned;
  Map<String, dynamic>? flutterVersion;
  bool verifying = false;
  RustBuild? _rust;

  final String appDirectory;
  FlutterBuild(
    this.options, {
    required this.name,
    super.root,
    this.appDirectory = '.',
  });

  /// Return null for projects without Rust. Evaluated after Pub resolution.
  RustBuild? get rust => null;
  String get defaultFlavor => '';
  File get flutterVersionFile => file('$package/pubspec.yaml');
  Iterable<File> get downloadedInputs => const [];
  Map<String, String> get rustTargets => _rust?.targets ?? _targets;
  List<String> get inputFiles => [];
  List<String> get platforms => _platforms.where((p) => p != 'server').toList();

  /// Called after locked Pub resolution, before preparing Rust and building.
  Future<Json> prepareDependencies(
    List<String> targets,
    Map<String, String> env,
  ) async => {};
  Future<void> checkDependencies(Json data) async {}
  Future<void> prepareTools(Map<String, String> env) async {}
  Future<void> checkTools(Map<String, String> env) async {}
  Future<void> beforeBuild(
    Map<String, String> env,
    List<String> targets,
  ) async {}
  Future<void> afterBuild(FileSystemEntity artifact) async {}
  Future<void> cleanExtraOutputs() async {}
  Future<FileSystemEntity?> buildCustomTarget(
    Map<String, String> env,
    List<String> targets,
  ) async => null;

  String get package => appDirectory;
  @override
  Directory get workingDirectory => Directory('${root.path}/$package');

  Map<String, Directory> packages() {
    final config = file('$package/.dart_tool/package_config.json');
    return {
      for (final entry in readJson(config)['packages'] as List)
        entry['name'] as String: Directory.fromUri(
          config.uri.resolve(entry['rootUri'] as String),
        ),
    };
  }

  Future<void> run() async {
    platform = options.option('platform') ?? Platform.operatingSystem;
    if (!platforms.contains(platform)) {
      throw UnsupportedError('Unsupported platform: $platform.');
    }
    final host = platform == 'ios' ? 'macos' : platform;
    if (!['android', 'web', 'server'].contains(platform) &&
        host != Platform.operatingSystem) {
      throw UnsupportedError('$platform builds require a $host host.');
    }
    final directory = Directory(
      options.option('cache-dir') ?? '${root.path}/.offline-build/$platform',
    )..createSync(recursive: true);
    cache = Directory(directory.resolveSymbolicLinksSync());
    final lock = cached('.lock').openSync(mode: FileMode.append);
    try {
      lock.lockSync(FileLock.exclusive);
    } on FileSystemException {
      lock.closeSync();
      throw StateError('Another build is using ${cache.path}.');
    }
    try {
      final preparing = options.rest.single == 'prepare';
      final manifest = cached('prepared.json');
      if (!preparing && !manifest.existsSync()) {
        throw StateError('No successful preparation found. Run prepare first.');
      }
      final prepared = preparing ? null : readJson(manifest);
      if (prepared != null && prepared['schema'] != 4) {
        throw StateError('Preparation format changed. Run prepare again.');
      }
      if (prepared != null) {
        _rust = prepared['rust'] == null
            ? null
            : RustBuild.fromJson(
                (prepared['rust'] as Map).cast<String, dynamic>(),
              );
      }
      epoch = prepared == null
          ? await sourceDateEpoch(root, options.option('source-date-epoch'))
          : prepared['source_date_epoch'] as int;
      unsigned = prepared == null
          ? options.flag('unsigned')
          : prepared['unsigned'] as bool;
      if (prepared != null &&
          ((options.flag('unsigned') && !unsigned) ||
              (options.option('source-date-epoch') != null &&
                  await sourceDateEpoch(
                        root,
                        options.option('source-date-epoch'),
                      ) !=
                      epoch))) {
        throw StateError('Build inputs changed. Run prepare again.');
      }
      dartDefines = options.wasParsed('dart-define')
          ? options.multiOption('dart-define')
          : prepared == null
          ? []
          : (prepared['dart_defines'] as List).cast<String>();
      flutter = File(
        options.option('flutter') ??
            (prepared == null
                ? await _executable('flutter')
                : prepared['flutter'] as String),
      ).resolveSymbolicLinksSync();
      if (prepared == null) {
        await prepare();
      } else if (options.rest.single == 'verify') {
        if (options.flag('analyze-size') ||
            options.wasParsed('code-size-directory')) {
          throw ArgumentError(
            'Size analysis is not supported during verification.',
          );
        }
        await verify(prepared);
      } else {
        await build(prepared);
      }
    } finally {
      lock.unlockSync();
      lock.closeSync();
    }
  }

  List<String>? get selectedPlatforms {
    final value = options.option('target-platform');
    if (value == null) return null;
    final platforms = value.split(',').map((p) => p.trim()).toList();
    if (platforms.toSet().length != platforms.length ||
        platforms.any(
          (p) => !p.startsWith('$platform-') || !rustTargets.containsKey(p),
        ) ||
        !['android', 'linux'].contains(platform) ||
        (platform != 'android' && platforms.length != 1)) {
      throw FormatException(
        'Select targets for $platform from ${rustTargets.keys.where((p) => p.startsWith('$platform-')).join(', ')}. '
        'Only Android supports multiple selected targets.',
      );
    }
    if (platform == 'linux' && platforms.single != defaultTargets.single) {
      throw UnsupportedError(
        'Linux builds require a matching host architecture.',
      );
    }
    return platforms;
  }

  List<String> get defaultTargets {
    if (platform == 'android') return rustTargets.keys.take(3).toList();
    if (platform == 'macos') return ['macos-x64', 'macos-arm64'];
    if (platform == 'ios') return ['ios-arm64'];
    if (platform == 'web') return ['web'];
    final architecture = Abi.current().toString().split('_').last;
    if (!['x64', 'arm64'].contains(architecture)) {
      throw UnsupportedError('Unsupported host architecture: $architecture.');
    }
    return [
      '${platform == 'server' ? Platform.operatingSystem : platform}-$architecture',
    ];
  }

  Future<Map<String, String>> fingerprint() async {
    final paths = [
      '$package/pubspec.yaml',
      '$package/pubspec.lock',
      ...inputFiles,
      if (file('$package/pubspec_overrides.yaml').existsSync())
        '$package/pubspec_overrides.yaml',
    ];
    if (!['web', 'server'].contains(platform)) {
      void configurations(Directory directory) {
        for (final entry in directory.listSync(followLinks: false)) {
          final name = entry.uri.pathSegments.where((p) => p.isNotEmpty).last;
          if (entry is Directory) {
            if (!name.startsWith('.') &&
                ![
                  'build',
                  'Pods',
                  'ephemeral',
                  'FlutterGeneratedPluginSwiftPackage',
                ].contains(name)) {
              configurations(entry);
            }
          } else if (entry is File &&
              (name == 'CMakeLists.txt' ||
                  name == 'Podfile' ||
                  name.endsWith('.gradle.kts') ||
                  name.endsWith('.properties') &&
                      name != 'local.properties' &&
                      name != 'key.properties' ||
                  name.endsWith('.pbxproj') ||
                  name.endsWith('.xcconfig') ||
                  name.endsWith('.xcscheme') ||
                  name == 'Package.swift' ||
                  name == 'Podfile.lock' ||
                  name == 'Package.resolved')) {
            if (![
              'Generated.xcconfig',
              'Flutter-Generated.xcconfig',
            ].contains(name)) {
              paths.add(entry.uri.path.substring(root.uri.path.length));
            }
          }
        }
      }

      configurations(Directory('${root.path}/$package/$platform'));
    }
    final result = {for (final path in paths) path: await digest(file(path))};
    // Include the resolved shared implementation, including local overrides.
    final library = File.fromUri(
      (await Isolate.resolvePackageUri(
        Uri.parse('package:generate_leap/build.dart'),
      ))!,
    );
    for (final entry
        in library.parent
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()) {
      if (entry.path.endsWith('.dart')) {
        result['generate_leap/${entry.uri.path.substring(library.parent.uri.path.length)}'] =
            await digest(entry);
      }
    }
    return result;
  }

  Future<Map<String, String>> environment({
    required bool offline,
    String? rustup,
    String? channel,
    bool compileLauncher = false,
  }) async {
    writeIfChanged(
      cached('gradle/init.d/generate-leap-offline.gradle'),
      "if (System.getenv('GENERATE_LEAP_OFFLINE_BUILD') == '1') {\n"
      '    gradle.startParameter.offline = true\n}\n'
      "if (System.getenv('GENERATE_LEAP_REPRODUCIBILITY_CHECK') == '1') {\n"
      '    gradle.startParameter.buildCacheEnabled = false\n}\n',
    );
    final environment = {
      for (final entry in Platform.environment.entries)
        (Platform.isWindows ? entry.key.toUpperCase() : entry.key): entry.value,
      'PUB_CACHE': '${cache.path}/pub-cache',
      'GRADLE_USER_HOME': '${cache.path}/gradle',
      if (_rust != null) 'CARGO_HOME': '${cache.path}/cargo',
      if (_rust != null) 'CARGO_NET_OFFLINE': '$offline',
      'GENERATE_LEAP_OFFLINE_BUILD': offline ? '1' : '0',
      'CI': 'true',
      'COCOAPODS_DISABLE_STATS': 'true',
      'SOURCE_DATE_EPOCH': '$epoch',
      'TZ': 'UTC',
      'LANG': 'C',
      'LC_ALL': 'C',
      'ZERO_AR_DATE': '1',
      if (_rust != null) 'CARGO_INCREMENTAL': '0',
      if (_rust != null) 'CARGO_TARGET_DIR': '${cache.path}/cargo-target',
      'EM_CACHE': '${cache.path}/emscripten',
      'PYTHONHASHSEED': '0',
      'GENERATE_LEAP_UNSIGNED_BUILD': unsigned ? '1' : '0',
      'GENERATE_LEAP_REPRODUCIBILITY_CHECK': verifying ? '1' : '0',
    };
    if (_rust != null) {
      environment.addAll(
        reproducibleEnvironment(
          sourceRoot: _rust!.sourceRoot.uri,
          prefix: '/$name',
          outputDirectory: Directory('${cache.path}/cargo-target').uri,
          windows:
              platform == 'windows' ||
              platform == 'server' && Platform.isWindows,
          environment: environment,
        )..removeWhere(
          (key, _) =>
              platform != 'web' &&
              const [
                'CFLAGS',
                'CXXFLAGS',
                'CC_SHELL_ESCAPED_FLAGS',
              ].contains(key),
        ),
      );
    }
    if (unsigned && platform == 'macos') {
      final settings = cached('unsigned.xcconfig');
      writeIfChanged(
        settings,
        'CODE_SIGNING_ALLOWED = NO\nCODE_SIGNING_REQUIRED = NO\n',
      );
      environment['XCODE_XCCONFIG_FILE'] = settings.path;
    }
    if (rustup != null) {
      // Hooks retain PATH but filter CARGO_* and RUSTUP_*. The native Dart
      // launcher restores those variables on every supported host OS.
      final directory = '${cache.path}/bin';
      final userHome =
          Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME']!;
      final variables = {
        'CARGO_HOME': '${cache.path}/cargo',
        'RUSTUP_HOME':
            Platform.environment['RUSTUP_HOME'] ?? '$userHome/.rustup',
        'RUSTUP_TOOLCHAIN': channel!,
        'RUSTUP_AUTO_INSTALL': offline ? '0' : '1',
        'CARGO_NET_OFFLINE': '$offline',
        for (final name in [
          'SOURCE_DATE_EPOCH',
          'TZ',
          'LANG',
          'LC_ALL',
          'ZERO_AR_DATE',
          'CARGO_INCREMENTAL',
          'CARGO_TARGET_DIR',
        ])
          name: environment[name]!,
      };
      final wrapper = File(
        '$directory/rustup${Platform.isWindows ? '.exe' : ''}',
      );
      writeJson(File('$directory/rustup.json'), {
        'executable': rustup,
        'environment': variables,
        'source_root': _rust!.sourceRoot.uri.toString(),
        'prefix': '/$name',
      });
      if (compileLauncher) {
        await command(Platform.resolvedExecutable, [
          'compile',
          'exe',
          (await Isolate.resolvePackageUri(
            Uri.parse('package:generate_leap/src/rustup.dart'),
          ))!.toFilePath(),
          '-o',
          wrapper.path,
        ], environment);
      } else if (!wrapper.existsSync()) {
        throw StateError('The Rust launcher is missing. Run prepare again.');
      }
      environment['PATH'] =
          '$directory${Platform.isWindows ? ';' : ':'}${environment['PATH'] ?? ''}';
      environment['RUSTUP_TOOLCHAIN'] = channel;
      environment['RUSTUP_AUTO_INSTALL'] = offline ? '0' : '1';
    }
    return environment;
  }

  Future<void> checkFlutter(Map<String, String> environment) async {
    final specification = loadYaml(
      file('$package/pubspec.yaml').readAsStringSync(),
    );
    final expected = specification['environment']?['flutter']?.toString();
    final version =
        jsonDecode(
              await command(
                flutter,
                [..._flutterFlags, '--version', '--machine'],
                environment,
                capture: true,
              ),
            )
            as Map<String, dynamic>;
    flutterVersion = {
      for (final name in [
        'frameworkVersion',
        'frameworkRevision',
        'engineRevision',
        'dartSdkVersion',
      ])
        name: version[name],
    };
    if (expected != null &&
        RegExp(r'^\d+\.\d+\.\d+$').hasMatch(expected) &&
        version['frameworkVersion'] != expected) {
      throw StateError(
        'Flutter $expected is required; $flutter reports ${version['frameworkVersion']}.',
      );
    }
  }

  Future<FileSystemEntity> buildTarget(
    Map<String, String> environment,
    String flavor,
    List<String> platforms,
  ) async {
    // --no-pub also skips release-specific plugin registration in Flutter.
    // Mark the resolved config as ours: Flutter skips dependency resolution
    // while still regenerating release tooling without dev-only plugins.
    final config = file('$package/.dart_tool/package_config.json');
    writeJson(config, {
      ...readJson(config),
      'generator': 'generate_leap_offline_build',
    });
    await beforeBuild(environment, platforms);
    final custom = await buildCustomTarget(environment, platforms);
    if (custom != null) return custom;
    await command(flutter, [
      ..._flutterFlags,
      'build',
      platform == 'android' ? 'apk' : platform,
      '--release',
      if (platform == 'android') '--no-android-gradle-daemon',
      if (flavor.isNotEmpty &&
          ['android', 'linux', 'windows'].contains(platform)) ...[
        '--flavor',
        flavor,
      ] else if (!dartDefines.any((value) => value.startsWith('flavor='))) ...[
        '--dart-define=flavor=$flavor',
      ],
      for (final value in dartDefines) '--dart-define=$value',
      if (['android', 'linux'].contains(platform)) ...[
        '--target-platform',
        platforms.join(','),
      ],
      if (platform == 'ios') '--no-codesign',
      if (platform == 'web') ...['--wasm', '--no-web-resources-cdn'],
      if (options.flag('analyze-size')) '--analyze-size',
      if (options.option('code-size-directory') case final directory?)
        '--code-size-directory=$directory',
    ], environment);
    final arch = platforms.singleOrNull?.split('-').last;
    final flavorDirectory = flavor.isEmpty ? '' : '$flavor/';
    final path = switch (platform) {
      'android' =>
        'app/outputs/flutter-apk/app${flavor.isEmpty ? '' : '-$flavor'}-release.apk',
      'linux' => 'linux/$arch/${flavorDirectory}release/bundle',
      'windows' => 'windows/$arch/${flavorDirectory}runner/Release',
      'macos' => 'macos/Build/Products/Release/$name.app',
      'ios' => 'ios/iphoneos/Runner.app',
      'web' => 'web',
      _ => throw UnsupportedError(platform),
    };
    final artifact = platform == 'android'
        ? file('$package/build/$path')
        : Directory('${root.path}/$package/build/$path');
    if (!artifact.existsSync()) {
      throw StateError('The build did not produce ${artifact.path}.');
    }
    await afterBuild(artifact);
    return artifact;
  }

  Future<void> prepare() async {
    final platforms = selectedPlatforms ?? defaultTargets;
    final manifest = cached('prepared.json');
    if (manifest.existsSync()) manifest.deleteSync();
    final flavor = options.option('flavor') ?? defaultFlavor;
    var env = await environment(offline: false);
    await checkFlutter(env);
    if (platform != 'server') {
      await command(flutter, [
        ..._flutterFlags,
        'precache',
        '--$platform',
      ], env);
    }
    await command(flutter, [
      ..._flutterFlags,
      'pub',
      'get',
      '--enforce-lockfile',
    ], env);
    final project = await prepareDependencies(platforms, env);
    _rust = rust;
    String? rustup;
    String? channel;
    if (_rust != null) {
      final toolchain = _rust!.toolchain.readAsStringSync();
      channel = RegExp(
        r'^channel\s*=\s*"([^"]+)"\s*$',
        multiLine: true,
      ).firstMatch(toolchain)?.group(1);
      if (channel == null ||
          !RegExp(
            r'^(\d+\.\d+\.\d+|nightly-\d{4}-\d{2}-\d{2})$',
          ).hasMatch(channel)) {
        throw StateError('Specify a pinned Rust toolchain.');
      }
      rustup = await _executable('rustup');
      env = await environment(
        offline: false,
        rustup: rustup,
        channel: channel,
        compileLauncher: true,
      );
      await command(rustup, [
        'toolchain',
        'install',
        channel,
        '--profile',
        'minimal',
        '--no-self-update',
        '--target',
        platforms.map((p) => rustTargets[p]!).join(','),
      ], env);
      await command(rustup, [
        'run',
        channel,
        'cargo',
        'fetch',
        '--locked',
        '--manifest-path',
        '${_rust!.crate.path}/Cargo.toml',
      ], env);
    }
    await prepareTools(env);
    await checkTools(env);
    stdout.writeln('Warming $platform dependencies with a release build...');
    await buildTarget(env, flavor, platforms);
    writeJson(manifest, {
      'schema': 4,
      'project': project,
      'rust': _rust?.toJson(),
      'source_date_epoch': epoch,
      'unsigned': unsigned,
      'flutter_version': flutterVersion,
      'platform': platform,
      'host': Platform.operatingSystem,
      'root': root.path,
      'flutter': flutter,
      'flavor': flavor,
      'dart_defines': dartDefines,
      'platforms': platforms,
      'sources': await fingerprint(),
      'native_downloads': await cacheDownloads(
        Directory('${root.path}/$package'),
        Directory('${cache.path}/native-downloads'),
        downloadedInputs,
      ),
      if (_rust != null) 'rustup': rustup,
      if (_rust != null) 'rust_channel': channel,
      if (_rust != null)
        'rust_launcher': await digest(
          cached('bin/rustup${Platform.isWindows ? '.exe' : ''}'),
        ),
    });
    stdout.writeln(
      'Prepared ${cache.path}. The build command can now run offline.',
    );
  }

  Future<FileSystemEntity> build(Json data) async {
    final platforms = selectedPlatforms;
    if (data['platform'] != platform ||
        data['host'] != Platform.operatingSystem ||
        data['root'] != root.path ||
        data['flutter'] != flutter ||
        !_sameMap(await fingerprint(), data['sources'] as Map) ||
        jsonEncode(dartDefines) != jsonEncode(data['dart_defines']) ||
        (options.option('flavor') != null &&
            options.option('flavor') != data['flavor']) ||
        (platforms != null &&
            jsonEncode(platforms) != jsonEncode(data['platforms']))) {
      throw StateError(
        'Build inputs changed. Run prepare again for this configuration.',
      );
    }
    final env = await environment(
      offline: true,
      rustup: data['rustup'] as String?,
      channel: data['rust_channel'] as String?,
    );
    if (_rust != null &&
        await digest(cached('bin/rustup${Platform.isWindows ? '.exe' : ''}')) !=
            data['rust_launcher']) {
      throw StateError('The Rust launcher changed. Run prepare again.');
    }
    await checkFlutter(env);
    await checkTools(env);
    if (!_sameMap(flutterVersion!, data['flutter_version'] as Map)) {
      throw StateError(
        'The Flutter/engine/Dart revision changed. Run prepare again.',
      );
    }
    await command(flutter, [
      ..._flutterFlags,
      'pub',
      'get',
      '--offline',
      '--enforce-lockfile',
    ], env);
    final targets = (data['platforms'] as List).cast<String>();
    await checkDependencies((data['project'] as Map).cast<String, dynamic>());
    await restoreDownloads(
      Directory('${root.path}/$package'),
      Directory('${cache.path}/native-downloads'),
      (data['native_downloads'] as Map).cast<String, dynamic>(),
    );
    if (_rust != null) {
      final installed = const LineSplitter().convert(
        await command(
          data['rustup'] as String,
          [
            'target',
            'list',
            '--installed',
            '--toolchain',
            data['rust_channel'] as String,
          ],
          env,
          capture: true,
        ),
      );
      final missing = targets
          .map((p) => rustTargets[p]!)
          .where((p) => !installed.contains(p));
      if (missing.isNotEmpty) {
        throw StateError(
          'Missing Rust targets: ${missing.join(', ')}. Run prepare again.',
        );
      }
    }
    final artifact = await buildTarget(env, data['flavor'] as String, targets);
    stdout.writeln('Offline $platform build: ${artifact.path}');
    return artifact;
  }

  Future<void> verify(Json data) async {
    verifying = true;
    final report = Directory('${cache.path}/reproducibility')
      ..createSync(recursive: true);
    // A previous success must not survive a failed or interrupted new attempt.
    for (final name in ['first.json', 'second.json', 'result.json']) {
      final previous = File('${report.path}/$name');
      if (previous.existsSync()) previous.deleteSync();
    }
    final env = await environment(
      offline: true,
      rustup: data['rustup'] as String?,
      channel: data['rust_channel'] as String?,
    );
    final snapshots = <Json>[];
    final archiveHashes = <String>[];
    for (final pass in ['first', 'second']) {
      stdout.writeln('Reproducibility: $pass clean $platform build');
      // Resolve packages before clean removes package_config.json. Cargo outputs
      // live in the private Pub cache, outside Flutter's build directory.
      await command(flutter, [
        ..._flutterFlags,
        'pub',
        'get',
        '--offline',
        '--enforce-lockfile',
      ], env);
      if (_rust != null) {
        await command(data['rustup'] as String, [
          'run',
          data['rust_channel'] as String,
          'cargo',
          'clean',
          '--offline',
          '--manifest-path',
          '${_rust!.crate.path}/Cargo.toml',
        ], env);
      }
      await command(flutter, [..._flutterFlags, 'clean'], env);
      // Flutter clean logs some deletion failures without failing the command.
      for (final name in ['build', '.dart_tool']) {
        if (Directory('${root.path}/$package/$name').existsSync()) {
          throw StateError(
            'flutter clean left $package/$name behind; refusing an incremental comparison.',
          );
        }
      }
      await cleanExtraOutputs();
      final artifact = await build(data);
      final snapshot = await artifactManifest(artifact);
      snapshots.add(snapshot);
      writeJson(File('${report.path}/$pass.json'), snapshot);
      if (artifact is Directory) {
        final tar =
            platform == 'linux' || platform == 'server' && Platform.isLinux;
        final archive = File('${report.path}/$pass.${tar ? 'tar.gz' : 'zip'}');
        final encode = tar ? reproducibleTarGz : reproducibleZip;
        await encode(
          artifact,
          archive,
          epoch,
          prefix: platform == 'macos'
              ? '$name.app'
              : platform == 'ios'
              ? 'Payload/Runner.app'
              : null,
        );
        archiveHashes.add(await digest(archive));
        await archive.delete();
      }
    }
    final differences = manifestDifferences(snapshots[0], snapshots[1]);
    if (archiveHashes.length == 2 && archiveHashes[0] != archiveHashes[1]) {
      differences.add('portable archive');
    }
    writeJson(File('${report.path}/result.json'), {
      'platform': platform,
      'flavor': data['flavor'],
      'targets': data['platforms'],
      'source_date_epoch': epoch,
      'unsigned': unsigned,
      'flutter_version': flutterVersion,
      'scope':
          'Two clean offline builds on the same host and checkout, including raw artifacts and portable archives. Store/installer packaging and signing are separate.',
      'archive_sha256': archiveHashes,
      'reproducible': differences.isEmpty,
      'differences': differences,
    });
    if (differences.isNotEmpty) {
      throw StateError(
        'Non-reproducible $platform artifact: ${differences.join(', ')}. See ${report.path}.',
      );
    }
    stdout.writeln(
      'Reproducible $platform artifact: ${snapshots.first.length} matching entries. Report: ${report.path}',
    );
  }
}

bool _sameMap(Map actual, Map expected) =>
    actual.length == expected.length &&
    actual.entries.every((e) => expected[e.key] == e.value);

Future<String> _executable(String name) async {
  final result = await Process.run(Platform.isWindows ? 'where.exe' : 'which', [
    name,
  ]);
  if (result.exitCode != 0) {
    throw StateError('Install $name before running prepare.');
  }
  final paths = const LineSplitter().convert(result.stdout as String);
  return File(
    paths.firstWhere(
      (p) =>
          !Platform.isWindows ||
          RegExp(r'\.(exe|bat|cmd)$', caseSensitive: false).hasMatch(p),
    ),
  ).absolute.path;
}

/// Optional Rust inputs for a Flutter project. Other projects leave rust null.
class RustBuild {
  final Directory crate;
  final Directory sourceRoot;
  final File toolchain;
  final Map<String, String> targets;

  RustBuild({
    required this.crate,
    Directory? sourceRoot,
    File? toolchain,
    this.targets = _targets,
  }) : sourceRoot = sourceRoot ?? crate,
       toolchain = toolchain ?? File('${crate.path}/rust-toolchain.toml');

  Json toJson() => {
    'crate': crate.path,
    'source_root': sourceRoot.path,
    'toolchain': toolchain.path,
    'targets': targets,
  };
  factory RustBuild.fromJson(Json data) => RustBuild(
    crate: Directory(data['crate'] as String),
    sourceRoot: Directory(data['source_root'] as String),
    toolchain: File(data['toolchain'] as String),
    targets: (data['targets'] as Map).cast<String, String>(),
  );
}
