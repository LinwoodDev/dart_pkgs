import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:synchronized/synchronized.dart';

@JS('pdfrxPlusBaseModulesUrl')
external set _baseModulesUrl(String value);
@JS('PdfiumWasmCommunicator')
external _Communicator get _communicator;

extension type _Communicator(JSObject _) implements JSObject {
  external JSPromise<JSAny?> sendCommand(String command, JSAny? parameters);
}

final _handles = Expando<int>('pdfrx_plus WASM documents');

void configureBackend({String? wasmModulesUrl}) {
  if (Pdfrx.pdfiumWasmModulesUrl == 'assets/packages/pdfrx_plus/assets/') {
    return;
  }
  _baseModulesUrl =
      wasmModulesUrl ??
      Pdfrx.pdfiumWasmModulesUrl ??
      'assets/packages/pdfrx/assets/';
  Pdfrx.pdfiumWasmModulesUrl = 'assets/packages/pdfrx_plus/assets/';
}

Future<Object?> _send(Map<String, Object?> request) async {
  final result = await _communicator
      .sendCommand('pdfrxPlusDispatch', request.jsify())
      .toDart;
  return result.dartify();
}

Future<void> initializeBackend() async {
  if (PdfrxEntryFunctions.instance is _EditingEntryFunctions) return;
  // Also support hosts which install a backend without initializing it.
  await PdfrxEntryFunctions.instance.init();
  await _send({'action': 'capabilities'});
  PdfrxEntryFunctions.instance = _EditingEntryFunctions(
    PdfrxEntryFunctions.instance,
  );
}

Future<Object?> execute(PdfDocument document, Map<String, Object?> request) {
  final handle = _handles[document];
  if (handle == null) {
    throw StateError(
      'Call configurePdfrxPlus before pdfrx initialization '
      'and initializePdfrxPlus before opening Web documents.',
    );
  }
  return _send({...request, 'handle': handle});
}

// This decorator preserves the original pdfrx document/page implementations.
// Open calls are serialized only while associating their worker handles; all
// rendering, saving, fonts, progressive loading and disposal remain in pdfrx.
class _EditingEntryFunctions extends PdfrxEntryFunctions {
  _EditingEntryFunctions(this.delegate);
  final PdfrxEntryFunctions delegate;
  final _openLock = Lock();
  Future<PdfDocument> _open(Future<PdfDocument> Function() callback) =>
      _openLock.synchronized(() async {
        final before = (await _send({'action': 'handles'}) as List)
            .cast<num>()
            .map((n) => n.toInt())
            .toSet();
        final doc = await callback();
        try {
          final after = (await _send({'action': 'handles'}) as List)
              .cast<num>()
              .map((n) => n.toInt())
              .toSet();
          final added = after.difference(before);
          if (added.length != 1) {
            throw StateError('Unable to associate pdfrx Web document handle');
          }
          _handles[doc] = added.single;
          return doc;
        } catch (_) {
          await doc.dispose();
          rethrow;
        }
      });
  @override
  PdfrxBackendType get backendType => delegate.backendType;
  @override
  Future<void> init() => delegate.init();
  @override
  Future<T> suspendPdfiumWorkerDuringAction<T>(FutureOr<T> Function() action) =>
      delegate.suspendPdfiumWorkerDuringAction(action);
  @override
  Future<R> compute<M, R>(FutureOr<R> Function(M) callback, M message) =>
      delegate.compute(callback, message);
  @override
  Future<void> stopBackgroundWorker() => delegate.stopBackgroundWorker();
  @override
  Future<PdfDocument> createNew({required String sourceName}) =>
      _open(() => delegate.createNew(sourceName: sourceName));
  @override
  Future<PdfDocument> createFromJpegData(
    Uint8List data, {
    required double width,
    required double height,
    required String sourceName,
  }) => _open(
    () => delegate.createFromJpegData(
      data,
      width: width,
      height: height,
      sourceName: sourceName,
    ),
  );
  @override
  Future<PdfDocument> openAsset(
    String name, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
  }) => _open(
    () => delegate.openAsset(
      name,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      useProgressiveLoading: useProgressiveLoading,
    ),
  );
  @override
  Future<PdfDocument> openData(
    Uint8List data, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    String? sourceName,
    bool allowDataOwnershipTransfer = false,
    bool useProgressiveLoading = false,
    int? maxSizeToCacheOnMemory,
    void Function()? onDispose,
  }) => _open(
    () => delegate.openData(
      data,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      sourceName: sourceName,
      allowDataOwnershipTransfer: allowDataOwnershipTransfer,
      useProgressiveLoading: useProgressiveLoading,
      maxSizeToCacheOnMemory: maxSizeToCacheOnMemory,
      onDispose: onDispose,
    ),
  );
  @override
  Future<PdfDocument> openFile(
    String path, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
  }) => _open(
    () => delegate.openFile(
      path,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      useProgressiveLoading: useProgressiveLoading,
    ),
  );
  @override
  Future<PdfDocument> openCustom({
    required FutureOr<int> Function(Uint8List, int, int) read,
    required int fileSize,
    required String sourceName,
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    int? maxSizeToCacheOnMemory,
    void Function()? onDispose,
  }) => _open(
    () => delegate.openCustom(
      read: read,
      fileSize: fileSize,
      sourceName: sourceName,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      useProgressiveLoading: useProgressiveLoading,
      maxSizeToCacheOnMemory: maxSizeToCacheOnMemory,
      onDispose: onDispose,
    ),
  );
  @override
  Future<PdfDocument> openUri(
    Uri uri, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    PdfDownloadProgressCallback? progressCallback,
    bool preferRangeAccess = false,
    Map<String, String>? headers,
    bool withCredentials = false,
    Duration? timeout,
  }) => _open(
    () => delegate.openUri(
      uri,
      passwordProvider: passwordProvider,
      firstAttemptByEmptyPassword: firstAttemptByEmptyPassword,
      useProgressiveLoading: useProgressiveLoading,
      progressCallback: progressCallback,
      preferRangeAccess: preferRangeAccess,
      headers: headers,
      withCredentials: withCredentials,
      timeout: timeout,
    ),
  );
  @override
  Future<void> configureFontEnvironment({
    String? fontCachePath,
    List<String> fontPaths = const [],
  }) => delegate.configureFontEnvironment(
    fontCachePath: fontCachePath,
    fontPaths: fontPaths,
  );
  @override
  Future<void> reloadFonts() => delegate.reloadFonts();
  @override
  Future<void> addFontData({
    required String face,
    required Uint8List data,
    String? resolvedFace,
  }) =>
      delegate.addFontData(face: face, data: data, resolvedFace: resolvedFace);
  @override
  Future<void> addFontFile({
    required String face,
    required String filePath,
    String? resolvedFace,
  }) => delegate.addFontFile(
    face: face,
    filePath: filePath,
    resolvedFace: resolvedFace,
  );
  @override
  Future<void> clearAllFontData() => delegate.clearAllFontData();
}
