import 'dart:io';

/// Keep Rust panic locations and Luau's C++ __FILE__ strings independent of the
/// checkout, Cargo cache, and native-assets output directory used by the builder.
Map<String, String> reproducibleEnvironment({
  required Uri sourceRoot,
  String prefix = '/source',
  required Uri outputDirectory,
  bool windows = false,
  Map<String, String>? environment,
}) {
  environment ??= Platform.environment;
  final home = environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  final cargoHome =
      environment['CARGO_HOME'] ??
      (home == null
          ? null
          : Directory(home).uri.resolve('.cargo/').toFilePath());
  final prefixes = {
    if (cargoHome != null) _path(Directory(cargoHome)): '/cargo',
    _path(Directory.fromUri(sourceRoot)): prefix,
    _path(Directory.fromUri(outputDirectory)): '$prefix/native-build',
  };
  // Cargo splits RUSTFLAGS on whitespace. The encoded form also supports paths
  // containing spaces, and takes precedence over RUSTFLAGS.
  final encoded = environment['CARGO_ENCODED_RUSTFLAGS'];
  final rustFlags = [
    if (encoded != null)
      ...encoded.split('\u001f').where((flag) => flag.isNotEmpty)
    else
      ...?environment['RUSTFLAGS']
          ?.split(RegExp(r'\s+'))
          .where((flag) => flag.isNotEmpty),
    for (final entry in prefixes.entries)
      '--remap-path-prefix=${entry.key}=${entry.value}',
    if (windows) ...[
      '-C',
      'link-arg=/Brepro',
      '-C',
      'link-arg=/PDBALTPATH:%_PDB%',
    ],
  ];
  String compilerFlags(String variable) => [
    ?environment![variable],
    if (windows) ...['/Brepro', '/experimental:deterministic'],
    for (final entry in prefixes.entries)
      '"${windows ? '/pathmap:' : '-ffile-prefix-map='}${entry.key.replaceAll('\\', '/')}=${entry.value}"',
  ].join(' ');
  return {
    'CARGO_ENCODED_RUSTFLAGS': rustFlags.join('\u001f'),
    // cc-rs otherwise splits on whitespace and passes the quotes literally.
    'CC_SHELL_ESCAPED_FLAGS': '1',
    'CFLAGS': compilerFlags('CFLAGS'),
    'CXXFLAGS': compilerFlags('CXXFLAGS'),
    'ZERO_AR_DATE': '1',
    'CARGO_INCREMENTAL': '0',
  };
}

String _path(Directory directory) =>
    directory.absolute.path.replaceFirst(RegExp(r'[/\\]+$'), '');
