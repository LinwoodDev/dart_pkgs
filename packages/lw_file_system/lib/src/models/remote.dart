import 'package:lw_file_system/lw_file_system.dart';

enum FileSyncStatus { localLatest, remoteLatest, synced, conflict, offline }

class SyncFile {
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
    if (remoteLastModified == null) {
      return FileSyncStatus.offline;
    }
    if (localLastModified == null || syncedLastModified == null) {
      return FileSyncStatus.remoteLatest;
    }
    if (syncedLastModified!.isBefore(remoteLastModified!)) {
      if (localLastModified!.isBefore(remoteLastModified!)) {
        return FileSyncStatus.remoteLatest;
      }
      if (!isDirectory) {
        return FileSyncStatus.conflict;
      }
      return FileSyncStatus.localLatest;
    }
    if (!localLastModified!.isAfter(syncedLastModified!)) {
      return FileSyncStatus.synced;
    }
    if (localLastModified!.isAfter(syncedLastModified!)) {
      return FileSyncStatus.localLatest;
    }
    return FileSyncStatus.remoteLatest;
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
