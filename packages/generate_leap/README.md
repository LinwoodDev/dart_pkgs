# Generate Leap

Helpers for generating assets and building reproducible artifacts. The existing
generate_leap.dart API for asset archives remains compatible.

## General build helpers

Import package:generate_leap/build.dart for BuildContext, JSON files, streamed
hashes and content-addressed download caching. BuildContext runs subprocesses in
a configurable working directory; it has no Flutter, Rust or project-layout
requirements. cacheDownloads takes explicitly selected inputs. restoreDownloads
checks hashes before restoring them; compiled outputs should never be selected.

Import package:generate_leap/reproducible.dart for sourceDateEpoch,
artifactManifest, manifestDifferences, reproducibleZip and reproducibleTarGz.
Archives preserve links and executable permissions with stable ordering and UTC
timestamps. Import package:generate_leap/native.dart for optional Rust/C/C++ path
remapping. These libraries are usable independently.

## Optional Flutter build adapter

Import package:generate_leap/flutter_build.dart for FlutterBuild and runFlutterBuild.
The default project is the current directory, with no flavor and no Rust:

```dart
import 'package:generate_leap/flutter_build.dart';

Future<void> main(List<String> args) => runFlutterBuild(
  args, (options) => FlutterBuild(options, name: 'example'),
);
```

Set root and appDirectory for another layout. Subclass only when extra input files,
downloads, generated assets or build steps are needed. Return a RustBuild from
the rust getter to opt into a pinned Rust toolchain; otherwise no Rust commands
are run. App flavors, third-party adapters and native crate paths belong to the
consumer. The common commands are:

- prepare: resolve locked inputs, record compiler revisions, cache downloads and warm a release build.
- build: validate prepared inputs and use offline dependency resolution.
- verify: remove build outputs twice, compare all artifact bytes, links and modes, and compare portable archives.

SOURCE_DATE_EPOCH defaults to the Git commit timestamp and can be supplied explicitly.
Inputs and reports live in .offline-build/<platform>. For an enforced network
boundary, run build or verify under the host OS's network sandbox.

Comparisons cover clean builds on the same host and checkout. Signing, store
installers and rebuilding precompiled dependencies need separate validation.
Consumers should pin an immutable published Git commit; local development can
use an ignored pubspec_overrides.yaml.
