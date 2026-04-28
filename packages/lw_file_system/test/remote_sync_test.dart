import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';

void main() {
  group('SyncFile status', () {
    test('treats newer local cache as localLatest even after global sync', () {
      final remoteModified = DateTime(2026, 3, 1);
      final localModified = DateTime(2026, 4, 1);
      final globalLastSynced = DateTime(2026, 4, 28);

      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: localModified,
        remoteLastModified: remoteModified,
        syncedLastModified: globalLastSynced,
      );

      expect(syncFile.status, FileSyncStatus.localLatest);
      expect(syncFile.needsSync, true);
    });

    test('treats equivalent local and remote timestamps as synced', () {
      final modified = DateTime(2026, 4, 28, 12);

      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: modified.add(const Duration(seconds: 1)),
        remoteLastModified: modified,
        syncedLastModified: DateTime(2026, 4, 27),
      );

      expect(syncFile.status, FileSyncStatus.synced);
    });

    test('detects conflict when both file copies changed after last sync', () {
      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: DateTime(2026, 4, 28, 13),
        remoteLastModified: DateTime(2026, 4, 28, 12),
        syncedLastModified: DateTime(2026, 4, 28, 11),
      );

      expect(syncFile.status, FileSyncStatus.conflict);
      expect(syncFile.hasConflict, true);
    });
  });
}
