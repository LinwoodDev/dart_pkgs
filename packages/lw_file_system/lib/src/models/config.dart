import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:lw_file_system/lw_file_system.dart';

typedef GetDirectoryCallback = Future<String> Function(
    ExternalStorage? storage);
typedef InitDatabaseCallback = Future<void> Function(Database database);

Future<void> initConfigStores(
    VersionChangeEvent event, Iterable<FileSystemConfig> configs) async {
  return initStores(
      event, configs.expand((e) => [e.storeName, e.currentDataStoreName]));
}

Future<void> initStores(
    VersionChangeEvent event, Iterable<String> stores) async {
  if (event.oldVersion < 1) {
    for (final store in stores) {
      event.database.createObjectStore(store);
    }
  }
}

class FileSystemConfig {
  final PasswordStorage passwordStorage;
  final String Function() getUnnamed;
  final String storeName, variant;
  final String? cacheVariant, pathVariant, dataStoreName, defaultStorageKey;
  final GetDirectoryCallback getDirectory;
  final OnUpgradeNeededFunction? onDatabaseUpgrade;
  final String database;
  final int databaseVersion;
  final String keySuffix;

  static String unnamedStatic() => 'Unnamed';
  static String unnamedDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  FileSystemConfig({
    required this.passwordStorage,
    required this.storeName,
    required this.getDirectory,
    this.getUnnamed = FileSystemConfig.unnamedDate,
    this.dataStoreName,
    this.onDatabaseUpgrade,
    this.variant = '',
    this.cacheVariant,
    this.pathVariant,
    this.defaultStorageKey,
    required this.database,
    required this.databaseVersion,
    this.keySuffix = '',
  });

  String get currentDataStoreName => dataStoreName ?? '$storeName-data';

  String get currentCacheVariant => cacheVariant ?? variant;
  String get currentPathVariant => pathVariant ?? variant;
  String get currentDefaultStorageName =>
      defaultStorageKey ?? 'lw_file_system.init.$database.$storeName';

  Future<void> runOnUpgradeNeeded(VersionChangeEvent event) async {
    if (onDatabaseUpgrade == null) {
      return initConfigStores(event, [this]);
    }
    await onDatabaseUpgrade?.call(event);
  }
}
