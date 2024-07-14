import 'package:lw_file_system/lw_file_system.dart';

enum FileSyncStatus { localLatest, remoteLatest, synced, conflict, offline }

class SyncFile {
  final bool isDirectory;
  final AssetLocation location;
  final DateTime? localLastModified, syncedLastModified, remoteLastModified;

  const SyncFile(
      {required this.isDirectory,
      required this.location,
      required this.localLastModified,
      required this.syncedLastModified,
      this.remoteLastModified});

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
}
