import 'package:lw_file_system/lw_file_system.dart';

enum FileSyncStatus { localLatest, remoteLatest, synced, conflict, offline }

class SyncFile {
  static const Duration _modifiedTolerance = Duration(seconds: 2);

  final bool isDirectory;
  final AssetLocation location;
  final DateTime? localLastModified, syncedLastModified, remoteLastModified;

  const SyncFile({
    required this.isDirectory,
    required this.location,
    required this.localLastModified,
    required this.syncedLastModified,
    this.remoteLastModified,
  });

  FileSyncStatus get status {
    bool isAfter(DateTime value, DateTime other) =>
        value.difference(other) > _modifiedTolerance;
    bool sameModified(DateTime value, DateTime other) =>
        value.difference(other).abs() <= _modifiedTolerance;

    if (remoteLastModified == null) {
      return FileSyncStatus.offline;
    }
    if (localLastModified == null) {
      return FileSyncStatus.remoteLatest;
    }

    if (sameModified(localLastModified!, remoteLastModified!)) {
      return FileSyncStatus.synced;
    }

    if (syncedLastModified == null) {
      return isAfter(localLastModified!, remoteLastModified!)
          ? FileSyncStatus.localLatest
          : FileSyncStatus.remoteLatest;
    }

    final localChanged = isAfter(localLastModified!, syncedLastModified!);
    final remoteChanged = isAfter(remoteLastModified!, syncedLastModified!);

    if (localChanged && remoteChanged) {
      if (!isDirectory &&
          !sameModified(localLastModified!, remoteLastModified!)) {
        return FileSyncStatus.conflict;
      }
    }

    if (isAfter(localLastModified!, remoteLastModified!)) {
      return FileSyncStatus.localLatest;
    }
    if (isAfter(remoteLastModified!, localLastModified!)) {
      return FileSyncStatus.remoteLatest;
    }

    return FileSyncStatus.synced;
  }

  String get path => location.path;

  /// Whether this file needs syncing
  bool get needsSync =>
      status == FileSyncStatus.localLatest ||
      status == FileSyncStatus.remoteLatest ||
      status == FileSyncStatus.conflict;

  /// Whether this file has a conflict
  bool get hasConflict => status == FileSyncStatus.conflict;

  /// Whether this file is synced
  bool get isSynced => status == FileSyncStatus.synced;

  /// Whether this file is offline
  bool get isOffline => status == FileSyncStatus.offline;

  /// Time since last local modification
  Duration? get timeSinceLocalModified => localLastModified != null
      ? DateTime.now().difference(localLastModified!)
      : null;

  /// Time since last remote modification
  Duration? get timeSinceRemoteModified => remoteLastModified != null
      ? DateTime.now().difference(remoteLastModified!)
      : null;

  /// Time since last sync
  Duration? get timeSinceSync => syncedLastModified != null
      ? DateTime.now().difference(syncedLastModified!)
      : null;

  /// Copy with new values
  SyncFile copyWith({
    bool? isDirectory,
    AssetLocation? location,
    DateTime? localLastModified,
    DateTime? syncedLastModified,
    DateTime? remoteLastModified,
  }) {
    return SyncFile(
      isDirectory: isDirectory ?? this.isDirectory,
      location: location ?? this.location,
      localLastModified: localLastModified ?? this.localLastModified,
      syncedLastModified: syncedLastModified ?? this.syncedLastModified,
      remoteLastModified: remoteLastModified ?? this.remoteLastModified,
    );
  }

  @override
  String toString() =>
      'SyncFile(path: $path, status: $status, isDirectory: $isDirectory)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncFile &&
          runtimeType == other.runtimeType &&
          location == other.location;

  @override
  int get hashCode => location.hashCode;
}
