import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

/// Types of network errors that can occur
enum NetworkErrorType {
  /// Connection failed (no network, host unreachable)
  connection,

  /// Request timed out
  timeout,

  /// SSL/TLS certificate error
  ssl,

  /// Authentication failed
  authentication,

  /// Server error (5xx)
  server,

  /// Client error (4xx)
  client,

  /// Unknown error
  unknown,
}

/// Exception thrown when a network operation fails
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final Object? originalException;
  final int? statusCode;

  const NetworkException(
    this.message, {
    this.type = NetworkErrorType.unknown,
    this.originalException,
    this.statusCode,
  });

  /// Whether this error is likely recoverable by retrying
  bool get isRecoverable => switch (type) {
    NetworkErrorType.connection => true,
    NetworkErrorType.timeout => true,
    NetworkErrorType.server => true,
    NetworkErrorType.authentication => false,
    NetworkErrorType.ssl => false,
    NetworkErrorType.client => statusCode == 429, // Rate limited
    NetworkErrorType.unknown => true,
  };

  @override
  String toString() => 'NetworkException: $message (type: $type)';
}

class NotModifiedException implements Exception {}

abstract class RemoteFileSystem extends DirectoryFileSystem {
  @override
  RemoteStorage get storage;

  RemoteFileSystem({required super.config, super.createDefault});

  final client = HttpClient();

  /// Default timeout for HTTP requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Timeout for file upload/download operations (longer)
  static const Duration transferTimeout = Duration(minutes: 5);

  Future<RawFileSystemEntity?> fetchRemoteAsset(
    String path, {
    bool readData = true,
    DateTime? currentLastModified,
    int? currentSize,
  });

  @override
  Future<RawFileSystemEntity?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    path = normalizePath(path);
    final cached = await getCachedContent(path);
    if (cached != null && !forceRemote) {
      return cached;
    }

    NetworkException? error;
    RawFileSystemEntity? asset;

    if (isOnline) {
      DateTime? currentLastModified;
      int? currentSize;

      if (cached != null &&
          cached is RawFileSystemFile &&
          cached.data != null) {
        currentSize = cached.data!.length;
        currentLastModified = await getCachedFileModified(path);
      }

      try {
        asset = await fetchRemoteAsset(
          path,
          readData: readData,
          currentLastModified: currentLastModified,
          currentSize: currentSize,
        );
      } on NotModifiedException {
        if (cached != null) return cached;
      } on NetworkException catch (e) {
        error = e;
      }
    } else {
      error = const NetworkException(
        'Offline',
        type: NetworkErrorType.connection,
      );
    }

    if (asset != null) return asset;

    // Try to recover from cache (directories)
    final cachedDir = await getCachedContent(path, includeDirectories: true);
    if (cachedDir != null) return cachedDir;

    if (error != null) throw error;

    return null;
  }

  Future<HttpClientResponse?> createRequest(
    List<String> path, {
    String method = 'GET',
    List<int>? bodyBytes,
    String? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = storage.buildVariantUri(
      variant: config.currentPathVariant,
      path: path,
    );
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            String.fromCharCodes(cert.sha1) == storage.certificateSha1;
    if (url == null) return null;

    // Set connection timeout
    client.connectionTimeout = timeout ?? defaultTimeout;

    try {
      final request = await client.openUrl(method, url);
      request.headers.add(
        'Authorization',
        'Basic ${base64Encode(utf8.encode('${storage.username}:${await config.passwordStorage?.read(storage)}'))}',
      );
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }
      if (body != null) {
        final bytes = utf8.encode(body);
        request.headers.add('Content-Length', bytes.length.toString());
        request.add(bytes);
      } else if (bodyBytes != null) {
        request.headers.add('Content-Length', bodyBytes.length.toString());
        request.add(bodyBytes);
      }
      return await request.close().timeout(
        timeout ?? defaultTimeout,
        onTimeout: () => throw TimeoutException(
          'Request timed out',
          timeout ?? defaultTimeout,
        ),
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'Network error: ${e.message}',
        type: NetworkErrorType.connection,
        originalException: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        'Request timed out',
        type: NetworkErrorType.timeout,
        originalException: e,
      );
    } on HandshakeException catch (e) {
      throw NetworkException(
        'SSL/TLS handshake failed: ${e.message}',
        type: NetworkErrorType.ssl,
        originalException: e,
      );
    }
  }

  Future<Uint8List> getBodyBytes(HttpClientResponse response) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (var chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<String> getBodyString(HttpClientResponse response) async {
    return utf8.decode(await getBodyBytes(response));
  }

  Future<RawFileSystemEntity?> getCachedContent(
    String path, {
    bool includeDirectories = false,
  }) async {
    final absolutePath = await getAbsolutePath(path);
    final file = File(absolutePath);
    // Only return cached content for files, not directories (unless requested).
    // Directories should always be fetched from remote to get the full listing,
    // otherwise we'd only see locally cached files and miss remote-only files.
    if (await file.exists()) {
      return RawFileSystemFile(
        AssetLocation(remote: storage.identifier, path: path),
        data: await file.readAsBytes(),
        cached: true,
      );
    }

    if (includeDirectories) {
      final directory = Directory(absolutePath);
      if (await directory.exists()) {
        final cacheDir = await getDirectory();
        return RawFileSystemDirectory(
          AssetLocation(remote: storage.identifier, path: path),
          assets: await directory
              .list()
              .map((e) {
                final childPath = p.relative(e.path, from: cacheDir);
                if (e is File) {
                  return RawFileSystemFile(
                    AssetLocation(remote: storage.identifier, path: childPath),
                    cached: true,
                  );
                }
                if (e is Directory) {
                  return RawFileSystemDirectory(
                    AssetLocation(remote: storage.identifier, path: childPath),
                  );
                }
                return null;
              })
              .whereNotNull()
              .toList(),
        );
      }
    }
    return null;
  }

  Future<void> cacheContent(
    String path,
    Uint8List content, {
    DateTime? modified,
  }) async {
    var absolutePath = await getAbsolutePath(path);
    var file = File(absolutePath);
    final directory = Directory(absolutePath);
    if (await directory.exists()) return;
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(content);
    if (modified != null) {
      await file.setLastModified(modified);
    }
  }

  Future<void> deleteCachedContent(String path) async {
    var absolutePath = await getAbsolutePath(path);
    var file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearCachedContent() async {
    var cacheDir = await getDirectory();
    var directory = Directory(cacheDir);
    final exists = await directory.exists();
    int maxRetries = 5;
    int retryCount = 0;

    while (exists && retryCount < maxRetries) {
      try {
        await directory.delete(recursive: true);
        // Directory deleted successfully, exit loop
        return;
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 32) {
          // Directory in use, retry after a short delay
          await Future.delayed(const Duration(seconds: 5));
          retryCount++;
        } else if (e.osError?.errorCode == 2) {
          // Directory not found, exit loop
          return;
        } else {
          // Handle unexpected FileSystemException, allowing it to propagate
          rethrow;
        }
      }
    }
    if (retryCount >= maxRetries) {
      throw Exception(
        'Maximum retry limit reached, directory might still be in use.',
      );
    }
  }

  Future<Map<String, Uint8List>> getCachedFiles() async {
    var cacheDir = await getDirectory();
    var files = <String, Uint8List>{};
    var dir = Directory(cacheDir);
    var list = await dir.list().toList();
    for (var file in list) {
      if (file is File) {
        var name = p.relative(file.path, from: cacheDir);
        var content = await file.readAsBytes();
        files[name] = content;
      }
    }
    return files;
  }

  Future<DateTime?> getCachedFileModified(String path) async {
    var absolutePath = await getAbsolutePath(path);
    final file = File(absolutePath);
    if (await file.exists()) {
      return file.lastModified();
    }
    final directory = Directory(absolutePath);
    if (await directory.exists()) {
      return storage.lastSynced;
    }
    return null;
  }

  Future<Map<String, DateTime>> getCachedFileModifieds() async {
    var cacheDir = await getDirectory();
    var files = <String, DateTime>{};
    var dir = Directory(cacheDir);
    var list = await dir.list().toList();
    for (final file in list) {
      final name = p.relative(file.path, from: cacheDir);
      final modified = await getCachedFileModified(name);
      if (modified != null) {
        files[name] = modified;
      }
    }
    return files;
  }

  Future<DateTime?> getRemoteFileModified(String path) async => null;

  Future<SyncFile> getSyncFile(String path) async {
    var localLastModified = await getCachedFileModified(path);
    var remoteLastModified = await getRemoteFileModified(path);
    var syncedLastModified = storage.lastSynced;
    final directory = Directory(await getAbsolutePath(path));

    return SyncFile(
      isDirectory: await directory.exists(),
      location: AssetLocation(remote: storage.identifier, path: path),
      localLastModified: localLastModified,
      remoteLastModified: remoteLastModified,
      syncedLastModified: syncedLastModified,
    );
  }

  Future<List<SyncFile>> getSyncFiles() async {
    var files = <SyncFile>[];
    var cacheDir = await getDirectory();
    var dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    var list = await dir.list().toList();
    for (var file in list) {
      if (file is File) {
        var name = p.relative(file.path, from: cacheDir);
        var localLastModified = await file.lastModified();
        var remoteLastModified = await getRemoteFileModified(name);
        var syncedLastModified = storage.lastSynced;
        files.add(
          SyncFile(
            isDirectory: false,
            location: AssetLocation(remote: storage.identifier, path: name),
            localLastModified: localLastModified,
            remoteLastModified: remoteLastModified,
            syncedLastModified: syncedLastModified,
          ),
        );
      }
    }
    return files;
  }

  final List<SyncOperation> _syncQueue = [];
  bool _isSyncing = false;
  bool _isPaused = false;
  bool _isOnline = true;

  /// Stream controller for sync events
  final _syncEventController = BehaviorSubject<SyncEvent>();

  /// Progress controller for sync progress updates
  final _progressController = BehaviorSubject<SyncProgress>.seeded(
    const SyncProgress(),
  );

  /// Stream controller for conflicts that need manual resolution
  final _conflictController = StreamController<SyncConflict>.broadcast();

  /// Pending conflicts waiting for resolution
  final Map<String, SyncConflict> _pendingConflicts = {};

  /// Optional callback for resolving conflicts automatically
  ConflictResolver? onConflict;

  /// Stream of sync events for UI updates
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  /// Stream of sync progress updates
  Stream<SyncProgress> get progressStream => _progressController.stream;

  /// Current sync progress
  SyncProgress get currentProgress => _progressController.value;

  /// Stream of conflicts that need resolution
  Stream<SyncConflict> get conflictStream => _conflictController.stream;

  /// List of pending conflicts waiting for resolution
  List<SyncConflict> get pendingConflicts => _pendingConflicts.values.toList();

  /// Whether there are pending conflicts
  bool get hasConflicts => _pendingConflicts.isNotEmpty;

  /// Current sync status
  bool get isSyncing => _isSyncing;
  bool get isPaused => _isPaused;
  bool get isOnline => _isOnline;

  /// Number of pending operations
  int get pendingOperationsCount => _syncQueue
      .where(
        (op) =>
            op.status == SyncOperationStatus.pending ||
            op.status == SyncOperationStatus.failed,
      )
      .length;

  /// Number of failed operations
  int get failedOperationsCount => _syncQueue
      .where((op) => op.status == SyncOperationStatus.permanentlyFailed)
      .length;

  Future<void> _addToQueue(SyncOperation op) async {
    // Remove duplicate update operations for the same path
    if (op.type == SyncOperationType.update) {
      _syncQueue.removeWhere((e) {
        if (e.type == SyncOperationType.update && e.path == op.path) {
          // Don't remove if it's currently being processed
          if (e.status == SyncOperationStatus.inProgress) {
            return false;
          }
          return true;
        }
        return false;
      });
    }
    _syncQueue.add(op);
    _triggerSync();
  }

  /// Pause sync operations
  void pauseSync() {
    _isPaused = true;
    _syncEventController.add(const SyncEvent(type: SyncEventType.paused));
  }

  /// Resume sync operations
  void resumeSync() {
    _isPaused = false;
    _syncEventController.add(const SyncEvent(type: SyncEventType.resumed));
    _triggerSync();
  }

  /// Update online status
  void setOnlineStatus(bool online) {
    final wasOnline = _isOnline;
    _isOnline = online;
    if (online && !wasOnline) {
      _syncEventController.add(
        const SyncEvent(
          type: SyncEventType.connectivityChanged,
          message: SyncMessage(SyncMessageType.backOnline),
        ),
      );
      _triggerSync();
    } else if (!online && wasOnline) {
      _syncEventController.add(
        const SyncEvent(
          type: SyncEventType.connectivityChanged,
          message: SyncMessage(SyncMessageType.offline),
        ),
      );
    }
  }

  /// Force retry all failed operations
  void retryFailedOperations() {
    for (final op in _syncQueue) {
      if (op.status == SyncOperationStatus.failed ||
          op.status == SyncOperationStatus.permanentlyFailed) {
        op.retryCount = 0;
        op.resetForRetry();
      }
    }
    _triggerSync();
  }

  /// Clear all permanently failed operations
  void clearFailedOperations() {
    _syncQueue.removeWhere(
      (op) => op.status == SyncOperationStatus.permanentlyFailed,
    );
  }

  /// Get next operation to process, respecting priority and retry delays
  SyncOperation? _getNextOperation() {
    // Sort by priority (high first) then by creation time
    final pendingOps =
        _syncQueue
            .where(
              (op) =>
                  op.status == SyncOperationStatus.pending ||
                  (op.status == SyncOperationStatus.failed &&
                      op.shouldRetryNow),
            )
            .toList()
          ..sort((a, b) {
            final priorityCompare = b.priority.index.compareTo(
              a.priority.index,
            );
            if (priorityCompare != 0) return priorityCompare;
            return a.createdAt.compareTo(b.createdAt);
          });

    return pendingOps.firstOrNull;
  }

  Future<void> _triggerSync() async {
    if (_isSyncing || _isPaused || !_isOnline) return;

    final nextOp = _getNextOperation();
    if (nextOp == null) return;

    _isSyncing = true;
    _syncEventController.add(const SyncEvent(type: SyncEventType.started));

    try {
      while (true) {
        final op = _getNextOperation();
        if (op == null || _isPaused || !_isOnline) break;

        op.markInProgress();
        _syncEventController.add(
          SyncEvent(
            type: SyncEventType.fileStarted,
            path: op.path,
            operation: op,
          ),
        );

        try {
          await _executeOperation(op);
          op.markCompleted();
          _syncQueue.remove(op);

          _syncEventController.add(
            SyncEvent(
              type: SyncEventType.fileCompleted,
              path: op.path,
              operation: op,
            ),
          );
        } catch (e) {
          op.markFailed(e.toString());

          _syncEventController.add(
            SyncEvent(
              type: SyncEventType.fileFailed,
              path: op.path,
              message: SyncMessage(SyncMessageType.syncFailed, error: e),
              operation: op,
            ),
          );

          debugPrint('Error syncing ${op.path} (attempt ${op.retryCount}): $e');

          // If there's a retry delay, wait before checking for more operations
          if (op.status == SyncOperationStatus.failed && !op.shouldRetryNow) {
            // Check if there are other operations that can be processed
            final otherOp = _getNextOperation();
            if (otherOp == null) {
              // Schedule retry
              Future.delayed(op.retryDelay, () {
                if (!_isSyncing) _triggerSync();
              });
              break;
            }
          }
        }
      }
    } finally {
      _isSyncing = false;
      _syncEventController.add(const SyncEvent(type: SyncEventType.completed));
    }
  }

  /// Execute a single sync operation
  Future<void> _executeOperation(SyncOperation op) async {
    switch (op.type) {
      case SyncOperationType.update:
        final absolutePath = await getAbsolutePath(op.path);
        final file = File(absolutePath);
        if (await file.exists()) {
          final data = await file.readAsBytes();
          await uploadFile(op.path, data);
        }
        break;
      case SyncOperationType.delete:
        await deleteRemoteAsset(op.path);
        break;
      case SyncOperationType.move:
        if (op.destination != null) {
          await moveRemoteAsset(op.path, op.destination!);
        }
        break;
      case SyncOperationType.createDir:
        await createRemoteDirectory(op.path);
        break;
    }
  }

  Future<void> uploadFile(String path, Uint8List data);
  Future<void> deleteRemoteAsset(String path);
  Future<void> moveRemoteAsset(String path, String newPath);
  Future<void> createRemoteDirectory(String path);

  /// Perform a full bidirectional sync for a path
  /// Returns a list of sync results
  Future<List<SyncResult>> syncPath(
    String path, {
    ConflictResolution conflictResolution = ConflictResolution.keepBoth,
    bool recursive = true,
  }) async {
    final results = <SyncResult>[];
    var syncFile = await getSyncFile(path);
    RawFileSystemEntity? downloadedAsset;

    switch (syncFile.status) {
      case FileSyncStatus.synced:
        results.add(
          SyncResult(path: path, action: SyncAction.none, success: true),
        );
        break;

      case FileSyncStatus.localLatest:
        // Upload local changes to remote
        await uploadCachedContent(path);
        results.add(
          SyncResult(path: path, action: SyncAction.uploaded, success: true),
        );
        break;

      case FileSyncStatus.remoteLatest:
        // Download remote changes to local
        try {
          final asset = await readAsset(path, forceRemote: true);
          downloadedAsset = asset;
          if (asset is RawFileSystemFile && asset.data != null) {
            await cacheContent(
              path,
              asset.data!,
              modified: syncFile.remoteLastModified,
            );
          } else if (asset is RawFileSystemDirectory) {
            var absolutePath = await getAbsolutePath(path);
            var dir = Directory(absolutePath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            syncFile = syncFile.copyWith(isDirectory: true);
          }
          results.add(
            SyncResult(
              path: path,
              action: SyncAction.downloaded,
              success: true,
            ),
          );
        } catch (e) {
          results.add(
            SyncResult(
              path: path,
              action: SyncAction.downloaded,
              success: false,
              error: e.toString(),
            ),
          );
        }
        break;

      case FileSyncStatus.conflict:
        results.add(
          await _resolveConflict(
            path,
            conflictResolution,
            remoteModified: syncFile.remoteLastModified,
          ),
        );
        break;

      case FileSyncStatus.offline:
        results.add(
          SyncResult(
            path: path,
            action: SyncAction.none,
            success: true,
            message: const SyncMessage(SyncMessageType.offlineSyncSkipped),
          ),
        );
        break;
    }

    // Handle recursive sync for directories
    if (recursive && syncFile.isDirectory) {
      final childPaths = <String>{};

      if (downloadedAsset is RawFileSystemDirectory) {
        childPaths.addAll(downloadedAsset.assets.map((e) => e.path));
      }

      final localAsset = await getAsset(path);
      if (localAsset is RawFileSystemDirectory) {
        childPaths.addAll(localAsset.assets.map((e) => e.path));
      }

      if (downloadedAsset == null && isOnline) {
        try {
          final remoteAsset = await readAsset(path, forceRemote: true);
          if (remoteAsset is RawFileSystemDirectory) {
            childPaths.addAll(remoteAsset.assets.map((e) => e.path));
          }
        } catch (_) {}
      }

      for (final childPath in childPaths) {
        results.addAll(
          await syncPath(
            childPath,
            conflictResolution: conflictResolution,
            recursive: true,
          ),
        );
      }
    }

    return results;
  }

  /// Resolve a sync conflict based on the resolution strategy
  Future<SyncResult> _resolveConflict(
    String path,
    ConflictResolution resolution, {
    DateTime? remoteModified,
  }) async {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        await uploadCachedContent(path);
        return SyncResult(
          path: path,
          action: SyncAction.uploaded,
          success: true,
          message: const SyncMessage(SyncMessageType.conflictKeptLocal),
        );

      case ConflictResolution.keepRemote:
        final asset = await readAsset(path, forceRemote: true);
        if (asset is RawFileSystemFile && asset.data != null) {
          await cacheContent(path, asset.data!, modified: remoteModified);
        }
        return SyncResult(
          path: path,
          action: SyncAction.downloaded,
          success: true,
          message: const SyncMessage(SyncMessageType.conflictKeptRemote),
        );

      case ConflictResolution.keepBoth:
        // Rename local file wlict suffix and download remote
        final conflictPath = _generateConflictPath(path);
        final localContent = await getCachedContent(path);
        if (localContent is RawFileSystemFile && localContent.data != null) {
          await cacheContent(conflictPath, localContent.data!);
          await _addToQueue(
            SyncOperation(
              SyncOperationType.update,
              conflictPath,
              priority: SyncPriority.high,
            ),
          );
        }
        // Download remote version
        final asset = await readAsset(path, forceRemote: true);
        if (asset is RawFileSystemFile && asset.data != null) {
          await cacheContent(path, asset.data!, modified: remoteModified);
        }
        return SyncResult(
          path: path,
          action: SyncAction.merged,
          success: true,
          message: SyncMessage(
            SyncMessageType.conflictKeptBoth,
            data: {'conflictPath': conflictPath},
          ),
        );

      case ConflictResolution.skip:
        return SyncResult(
          path: path,
          action: SyncAction.none,
          success: true,
          message: const SyncMessage(SyncMessageType.conflictSkipped),
        );
    }
  }

  /// Generate a conflict path with timestamp
  String _generateConflictPath(String path) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final ext = p.extension(path);
    final nameWithoutExt = p.withoutExtension(path);
    return '$nameWithoutExt (conflict $timestamp)$ext';
  }

  /// Perform a full sync of all cached paths
  ///
  /// If [paths] is provided, only those paths will be synced.
  /// Otherwise, all cached paths will be synced.
  Future<FullSyncResult> fullSync({
    List<String>? paths,
    ConflictResolution conflictResolution = ConflictResolution.skip,
  }) async {
    final startTime = DateTime.now();
    final allResults = <SyncResult>[];
    List<String> pathsToSync;
    if (paths != null) {
      pathsToSync = paths;
    } else {
      pathsToSync = getPinnedPaths();
    }

    _syncEventController.add(const SyncEvent(type: SyncEventType.started));
    _pendingConflicts.clear();

    _progressController.add(
      SyncProgress(
        totalFiles: pathsToSync.length,
        processedFiles: 0,
        isRunning: true,
        isPaused: false,
        pendingConflicts: 0,
        errors: 0,
      ),
    );

    for (var i = 0; i < pathsToSync.length; i++) {
      final path = pathsToSync[i];
      _syncEventController.add(
        SyncEvent(
          type: SyncEventType.fileStarted,
          path: path,
          progress: i / pathsToSync.length,
        ),
      );

      _progressController.add(
        _progressController.value.copyWith(
          currentFile: path,
          processedFiles: i,
        ),
      );

      try {
        final syncFile = await getSyncFile(path);

        if (syncFile.status == FileSyncStatus.conflict) {
          final result = await _handleConflictWithResolver(
            path,
            syncFile,
            conflictResolution,
          );
          if (result != null) {
            allResults.add(result);
          }
        } else {
          final results = await syncPath(
            path,
            conflictResolution: conflictResolution,
          );
          allResults.addAll(results);
        }
      } catch (e) {
        allResults.add(
          SyncResult(
            path: path,
            action: SyncAction.none,
            success: false,
            error: e.toString(),
          ),
        );
        _progressController.add(
          _progressController.value.copyWith(
            errors: _progressController.value.errors + 1,
          ),
        );
      }
    }

    _syncEventController.add(const SyncEvent(type: SyncEventType.completed));

    _progressController.add(
      _progressController.value.copyWith(
        isRunning: false,
        processedFiles: pathsToSync.length,
        currentFile: null,
        pendingConflicts: _pendingConflicts.length,
      ),
    );

    return FullSyncResult(
      results: allResults,
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  /// Handle a conflict, using the resolver callback if available
  Future<SyncResult?> _handleConflictWithResolver(
    String path,
    SyncFile syncFile,
    ConflictResolution defaultResolution,
  ) async {
    // Get the actual file contents for comparison
    final localContent = await getCachedContent(path);
    final remoteContent = await readAsset(path, forceRemote: true);

    final conflict = SyncConflict(
      path: path,
      localData: localContent is RawFileSystemFile ? localContent.data : null,
      remoteData: remoteContent is RawFileSystemFile
          ? remoteContent.data
          : null,
      localModified: syncFile.localLastModified,
      remoteModified: syncFile.remoteLastModified,
      lastSynced: syncFile.syncedLastModified,
    );

    // If we have a conflict resolver callback, use it
    if (onConflict != null) {
      final resolution = await onConflict!(conflict);
      return _resolveConflict(
        path,
        resolution,
        remoteModified: syncFile.remoteLastModified,
      );
    } else {
      // Queue the conflict for manual resolution
      _pendingConflicts[path] = conflict;
      _conflictController.add(conflict);

      _progressController.add(
        _progressController.value.copyWith(
          pendingConflicts: _pendingConflicts.length,
        ),
      );

      return null; // Conflict queued, not resolved yet
    }
  }

  /// Resolve a pending conflict with the specified resolution
  Future<SyncResult> resolveConflict(
    String path,
    ConflictResolution resolution,
  ) async {
    final conflict = _pendingConflicts.remove(path);
    if (conflict == null) {
      return SyncResult(
        path: path,
        action: SyncAction.none,
        success: false,
        message: const SyncMessage(SyncMessageType.noPendingConflict),
      );
    }

    final result = await _resolveConflict(
      path,
      resolution,
      remoteModified: conflict.remoteModified,
    );

    _progressController.add(
      _progressController.value.copyWith(
        pendingConflicts: _pendingConflicts.length,
      ),
    );

    return result;
  }

  /// Resolve all pending conflicts with the specified resolution
  Future<List<SyncResult>> resolveAllConflicts(
    ConflictResolution resolution,
  ) async {
    final results = <SyncResult>[];
    final paths = _pendingConflicts.keys.toList();

    for (final path in paths) {
      results.add(await resolveConflict(path, resolution));
    }

    return results;
  }

  /// Download a remote file/directory to local cache
  Future<void> pullFromRemote(String path, {bool recursive = true}) async {
    final asset = await readAsset(path, forceRemote: true);
    if (asset == null) return;

    if (asset is RawFileSystemFile) {
      if (asset.cached) return;
      final data = asset.data;
      if (data != null) {
        await cacheContent(path, data);
      }
    } else if (asset is RawFileSystemDirectory && recursive) {
      final absolutePath = await getAbsolutePath(path);
      await Directory(absolutePath).create(recursive: true);
      final remotePaths = <String>{};
      for (final child in asset.assets) {
        remotePaths.add(normalizePath(child.path));
        await pullFromRemote(child.path, recursive: true);
      }

      final localDir = Directory(absolutePath);
      if (await localDir.exists()) {
        final localFiles = localDir.listSync();
        for (final file in localFiles) {
          final fileName = p.basename(file.path);
          final childPath = normalizePath(p.url.join(path, fileName));

          if (!remotePaths.contains(childPath)) {
            await file.delete(recursive: true);
          }
        }
      }
    }
  }

  /// Sync all pinned paths - downloads them to local cache
  /// This should be called periodically or when connectivity is restored
  Future<void> syncPinnedPaths() async {
    final pinnedPaths = storage.getPinnedPaths(
      variant: config.currentCacheVariant,
    );
    for (final path in pinnedPaths) {
      await pullFromRemote(path, recursive: true);
    }
  }

  /// Check if a path is pinned for offline caching
  bool isPathPinned(String path) {
    return storage.isPathPinned(path, variant: config.currentCacheVariant);
  }

  /// Get all pinned paths for the current variant
  List<String> getPinnedPaths() {
    return storage.getPinnedPaths(variant: config.currentCacheVariant);
  }

  Future<List<SyncFile>> getAllSyncFiles() async {
    final paths = getPinnedPaths();
    final files = <SyncFile>[];
    for (final path in paths) {
      final asset = await getAsset(path);
      if (asset == null) continue;
      files.add(await getSyncFile(asset.path));
      if (asset is RawFileSystemDirectory) {
        for (final file in asset.assets) {
          files.add(await getSyncFile(file.path));
        }
      }
    }
    return files;
  }

  Future<void> uploadCachedContent(String path) async {
    final content = await getCachedContent(path);
    if (content == null) {
      return;
    }
    if (content is RawFileSystemFile) {
      final data = content.data;
      if (data != null) await updateFile(path, data, forceSync: true);
    }
  }

  @override
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    await cacheContent(path, data);

    if (forceSync) {
      await uploadFile(path, data);
    } else {
      await _addToQueue(SyncOperation(SyncOperationType.update, path));
    }
  }

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    await deleteCachedContent(path);
    await _addToQueue(SyncOperation(SyncOperationType.delete, path));
  }

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    newPath = normalizePath(newPath);

    final absolutePath = await getAbsolutePath(path);
    final absoluteNewPath = await getAbsolutePath(newPath);
    final dir = Directory(absolutePath);
    final file = File(absolutePath);
    if (await dir.exists()) {
      await dir.rename(absoluteNewPath);
    } else if (await file.exists()) {
      await file.rename(absoluteNewPath);
    }

    if (forceSync) {
      await moveRemoteAsset(path, newPath);
    } else {
      await _addToQueue(
        SyncOperation(SyncOperationType.move, path, destination: newPath),
      );
    }

    return getAsset(newPath);
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    path = normalizePath(path);
    final absolutePath = await getAbsolutePath(path);
    await Directory(absolutePath).create(recursive: true);

    await _addToQueue(SyncOperation(SyncOperationType.createDir, path));

    return RawFileSystemDirectory(
      AssetLocation(remote: storage.identifier, path: path),
    );
  }

  Future<void> cache(String path) async {
    final asset = await getAsset(path);
    if (asset is FileSystemDirectory) {
      var filePath = path;
      if (filePath.startsWith('/')) {
        filePath = filePath.substring(1);
      }
      filePath = universalPathContext.join(await getDirectory(), filePath);
      final directory = Directory(filePath);
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
    } else if (asset is RawFileSystemFile) {
      final data = asset.data;
      if (data != null) cacheContent(path, data);
    }
  }
}

enum SyncOperationType { update, delete, move, createDir }

/// Conflict resolution strategies for sync operations
enum ConflictResolution {
  /// Keep the local version, overwrite remote
  keepLocal,

  /// Keep the remote version, overwrite local
  keepRemote,

  /// Keep both versions (rename local with suffix)
  keepBoth,

  /// Skip this file during sync
  skip,
}

/// Represents the current status of a sync operation
enum SyncOperationStatus {
  /// Waiting to be processed
  pending,

  /// Currently being synced
  inProgress,

  /// Completed successfully
  completed,

  /// Failed, will retry
  failed,

  /// Failed permanently, won't retry
  permanentlyFailed,
}

/// Priority levels for sync operations
enum SyncPriority {
  /// Low priority - background sync
  low,

  /// Normal priority - user-initiated changes
  normal,

  /// High priority - user explicitly requested sync
  high,
}

class SyncOperation {
  final SyncOperationType type;
  final String path;
  final String? destination;
  final DateTime createdAt;
  final SyncPriority priority;
  int retryCount;
  DateTime? lastAttempt;
  SyncOperationStatus status;
  String? lastError;

  static const int maxRetries = 5;
  static const Duration baseRetryDelay = Duration(seconds: 2);

  SyncOperation(
    this.type,
    this.path, {
    this.destination,
    DateTime? createdAt,
    this.priority = SyncPriority.normal,
    this.retryCount = 0,
    this.lastAttempt,
    this.status = SyncOperationStatus.pending,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate the delay before the next retry using exponential backoff
  Duration get retryDelay {
    if (retryCount == 0) return Duration.zero;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final seconds = baseRetryDelay.inSeconds * (1 << (retryCount - 1));
    return Duration(seconds: seconds.clamp(0, 60));
  }

  /// Check if this operation should be retried now
  bool get shouldRetryNow {
    if (status != SyncOperationStatus.failed) return false;
    if (retryCount >= maxRetries) return false;
    if (lastAttempt == null) return true;
    return DateTime.now().difference(lastAttempt!) >= retryDelay;
  }

  /// Check if this operation has permanently failed
  bool get hasPermanentlyFailed =>
      retryCount >= maxRetries ||
      status == SyncOperationStatus.permanentlyFailed;

  /// Mark operation as failed
  void markFailed(String error) {
    retryCount++;
    lastAttempt = DateTime.now();
    lastError = error;
    status = retryCount >= maxRetries
        ? SyncOperationStatus.permanentlyFailed
        : SyncOperationStatus.failed;
  }

  /// Mark operation as in progress
  void markInProgress() {
    status = SyncOperationStatus.inProgress;
    lastAttempt = DateTime.now();
  }

  /// Mark operation as completed
  void markCompleted() {
    status = SyncOperationStatus.completed;
  }

  /// Reset operation for retry
  void resetForRetry() {
    status = SyncOperationStatus.pending;
  }

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'path': path,
    if (destination != null) 'destination': destination,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.toString(),
    'retryCount': retryCount,
    if (lastAttempt != null) 'lastAttempt': lastAttempt!.toIso8601String(),
    'status': status.toString(),
    if (lastError != null) 'lastError': lastError,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      SyncOperationType.values.firstWhere((e) => e.toString() == json['type']),
      json['path'],
      destination: json['destination'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      priority: json['priority'] != null
          ? SyncPriority.values.firstWhere(
              (e) => e.toString() == json['priority'],
            )
          : SyncPriority.normal,
      retryCount: json['retryCount'] ?? 0,
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
      status: json['status'] != null
          ? SyncOperationStatus.values.firstWhere(
              (e) => e.toString() == json['status'],
            )
          : SyncOperationStatus.pending,
      lastError: json['lastError'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperation &&
          type == other.type &&
          path == other.path &&
          destination == other.destination;

  @override
  int get hashCode => Object.hash(type, path, destination);
}

/// Event emitted during sync operations
class SyncEvent {
  final SyncEventType type;
  final String? path;
  final SyncMessage? message;
  final double? progress;
  final SyncOperation? operation;

  const SyncEvent({
    required this.type,
    this.path,
    this.message,
    this.progress,
    this.operation,
  });
}

enum SyncEventType {
  /// Sync started
  started,

  /// Processing a specific file
  fileStarted,

  /// File sync completed
  fileCompleted,

  /// File sync failed
  fileFailed,

  /// All sync operations completed
  completed,

  /// Sync encountered an error
  error,

  /// Sync was paused
  paused,

  /// Sync was resumed
  resumed,

  /// Connectivity changed
  connectivityChanged,
}

/// Actions that can be performed during sync
enum SyncAction {
  /// No action needed
  none,

  /// File was uploaded to remote
  uploaded,

  /// File was downloaded from remote
  downloaded,

  /// Files were merged (conflict resolution)
  merged,

  /// File was deleted
  deleted,
}

/// Message types for sync operations (for localization)
enum SyncMessageType {
  /// Back online after being offline
  backOnline,

  /// Now offline
  offline,

  /// Sync skipped because offline
  offlineSyncSkipped,

  /// Conflict resolved by keeping local version
  conflictKeptLocal,

  /// Conflict resolved by keeping remote version
  conflictKeptRemote,

  /// Conflict resolved by keeping both versions
  conflictKeptBoth,

  /// Conflict was skipped
  conflictSkipped,

  /// No pending conflict for the given path
  noPendingConflict,

  /// Sync operation failed
  syncFailed,
}

/// Structured message for sync operations
class SyncMessage {
  final SyncMessageType type;

  /// Additional data for the message (e.g., conflict path for keepBoth)
  final Map<String, dynamic> data;

  /// Error details (for syncFailed type)
  final Object? error;

  const SyncMessage(this.type, {this.data = const {}, this.error});

  /// Get the conflict path (for keepBoth resolution)
  String? get conflictPath => data['conflictPath'] as String?;
}

/// Result of a single sync operation
class SyncResult {
  final String path;
  final SyncAction action;
  final bool success;
  final String? error;
  final SyncMessage? message;

  const SyncResult({
    required this.path,
    required this.action,
    required this.success,
    this.error,
    this.message,
  });

  @override
  String toString() =>
      'SyncResult(path: $path, action: $action, success: $success${error != null ? ', error: $error' : ''})';
}

/// Result of a full sync operation
class FullSyncResult {
  final List<SyncResult> results;
  final DateTime startTime;
  final DateTime endTime;

  const FullSyncResult({
    required this.results,
    required this.startTime,
    required this.endTime,
  });

  /// Duration of the sync
  Duration get duration => endTime.difference(startTime);

  /// Number of successful operations
  int get successCount => results.where((r) => r.success).length;

  /// Number of failed operations
  int get failureCount => results.where((r) => !r.success).length;

  /// Number of files uploaded
  int get uploadedCount =>
      results.where((r) => r.action == SyncAction.uploaded && r.success).length;

  /// Number of files downloaded
  int get downloadedCount => results
      .where((r) => r.action == SyncAction.downloaded && r.success)
      .length;

  /// Number of conflicts resolved
  int get conflictsResolvedCount =>
      results.where((r) => r.action == SyncAction.merged && r.success).length;

  /// All errors encountered
  List<SyncResult> get errors => results.where((r) => !r.success).toList();

  /// Check if sync was fully successful
  bool get isFullySuccessful => failureCount == 0;

  @override
  String toString() =>
      'FullSyncResult(success: $successCount, failed: $failureCount, uploaded: $uploadedCount, downloaded: $downloadedCount, duration: ${duration.inSeconds}s)';
}

/// Represents a sync conflict that needs resolution
class SyncConflict {
  /// Path of the conflicting file
  final String path;

  /// Local file data (if available)
  final Uint8List? localData;

  /// Remote file data (if available)
  final Uint8List? remoteData;

  /// When the local file was last modified
  final DateTime? localModified;

  /// When the remote file was last modified
  final DateTime? remoteModified;

  /// When the file was last synced
  final DateTime? lastSynced;

  const SyncConflict({
    required this.path,
    this.localData,
    this.remoteData,
    this.localModified,
    this.remoteModified,
    this.lastSynced,
  });

  /// Size of the local file in bytes
  int? get localSize => localData?.length;

  /// Size of the remote file in bytes
  int? get remoteSize => remoteData?.length;

  /// Check if local is newer than remote
  bool get isLocalNewer =>
      localModified != null &&
      remoteModified != null &&
      localModified!.isAfter(remoteModified!);

  /// Check if remote is newer than local
  bool get isRemoteNewer =>
      localModified != null &&
      remoteModified != null &&
      remoteModified!.isAfter(localModified!);
}

/// Current sync progress information
class SyncProgress {
  /// Total number of files to sync
  final int totalFiles;

  /// Number of files processed so far
  final int processedFiles;

  /// Current file being processed
  final String? currentFile;

  /// Current operation being performed
  final SyncAction? currentAction;

  /// Number of bytes transferred
  final int bytesTransferred;

  /// Total bytes to transfer (if known)
  final int? totalBytes;

  /// Whether sync is currently running
  final bool isRunning;

  /// Whether sync is paused
  final bool isPaused;

  /// Number of pending conflicts
  final int pendingConflicts;

  /// Number of errors encountered
  final int errors;

  const SyncProgress({
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.currentFile,
    this.currentAction,
    this.bytesTransferred = 0,
    this.totalBytes,
    this.isRunning = false,
    this.isPaused = false,
    this.pendingConflicts = 0,
    this.errors = 0,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0.0;

  /// Progress as a percentage string
  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  /// Copy with new values
  SyncProgress copyWith({
    int? totalFiles,
    int? processedFiles,
    String? currentFile,
    SyncAction? currentAction,
    int? bytesTransferred,
    int? totalBytes,
    bool? isRunning,
    bool? isPaused,
    int? pendingConflicts,
    int? errors,
  }) {
    return SyncProgress(
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      currentFile: currentFile ?? this.currentFile,
      currentAction: currentAction ?? this.currentAction,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
      errors: errors ?? this.errors,
    );
  }
}

/// Callback for manual conflict resolution
/// Returns the resolution strategy to use for the given conflict
typedef ConflictResolver =
    Future<ConflictResolution> Function(SyncConflict conflict);
