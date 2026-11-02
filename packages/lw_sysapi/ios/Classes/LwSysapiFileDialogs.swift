import Flutter
import UIKit
import UniformTypeIdentifiers

final class LwSysapiFileDialogs: NSObject, UIDocumentPickerDelegate {
  weak var viewController: UIViewController?
  private var pending: FlutterResult?
  private var operation = ""
  private var extensionName = ""
  private var temporaryURL: URL?
  private var selectedURLs: [String: URL] = [:]
  private var directories: [URL] = []

  init(viewController: UIViewController?) {
    self.viewController = viewController
    super.init()
    let bookmarks = UserDefaults.standard.dictionary(forKey: "lw_sysapi.directories") ?? [:]
    for (_, value) in bookmarks {
      guard let data = value as? Data else { continue }
      var stale = false
      if let url = try? URL(resolvingBookmarkData: data, options: .withoutUI,
                           bookmarkDataIsStale: &stale), url.startAccessingSecurityScopedResource() {
        directories.append(url)
      }
    }
  }

  deinit { directories.forEach { $0.stopAccessingSecurityScopedResource() } }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
    let args = call.arguments as? [String: Any] ?? [:]
    if call.method == "readFile" {
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_path", message: "Missing file path", details: nil))
        return true
      }
      let url = selectedURLs[path] ?? URL(fileURLWithPath: path)
      DispatchQueue.global(qos: .userInitiated).async {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var contents: Data?
        var readError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readable in
          do { contents = try Data(contentsOf: readable) } catch { readError = error }
        }
        let message = coordinationError?.localizedDescription ?? readError?.localizedDescription
        let data = contents
        DispatchQueue.main.async {
          if let message = message {
            result(FlutterError(code: "read_failed", message: message, details: path))
          } else if let data = data {
            result(FlutterStandardTypedData(bytes: data))
          } else {
            result(FlutterError(code: "read_failed", message: "No document data was returned", details: path))
          }
        }
      }
      return true
    }
    guard ["pickFiles", "pickDirectory", "saveFile"].contains(call.method) else { return false }
    guard pending == nil else {
      result(FlutterError(code: "dialog_in_progress", message: "A file dialog is already open", details: nil))
      return true
    }
    guard let host = viewController else {
      result(FlutterError(code: "no_activity", message: "No view controller is available", details: nil))
      return true
    }
    pending = result
    operation = call.method
    let folder = call.method == "pickDirectory"
    if folder {
      if #available(iOS 13.0, *) {} else {
        finish(FlutterError(code: "unsupported", message: "Directory selection requires iOS 13", details: nil))
        return true
      }
    }
    if call.method == "saveFile" {
      guard let data = (args["data"] as? FlutterStandardTypedData)?.data,
            let name = args["name"] as? String else {
        finish(FlutterError(code: "invalid_arguments", message: "Save data and a filename are required", details: nil))
        return true
      }
      extensionName = args["extension"] as? String ?? ""
      let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
      let url = directory.appendingPathComponent(name)
      temporaryURL = url
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        do {
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
          try data.write(to: url)
          DispatchQueue.main.async {
            let picker: UIDocumentPickerViewController
            if #available(iOS 14.0, *) {
              picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
            } else {
              picker = UIDocumentPickerViewController(url: url, in: .exportToService)
            }
            present(picker, on: host)
          }
        } catch {
          DispatchQueue.main.async {
            finish(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
      return true
    }
    let extensions = args["extensions"] as? [String] ?? []
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      let types = folder ? [UTType.folder] : extensions.compactMap { UTType(filenameExtension: $0) }
      picker = UIDocumentPickerViewController(forOpeningContentTypes: types.isEmpty ? [.data] : types, asCopy: false)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: folder ? ["public.folder"] : ["public.data"], in: .open)
    }
    picker.allowsMultipleSelection = !folder && (args["multiple"] as? Bool ?? false)
    present(picker, on: host)
    return true
  }

  private func present(_ picker: UIDocumentPickerViewController, on host: UIViewController) {
    picker.delegate = self
    var presenter = host
    while let presented = presenter.presentedViewController { presenter = presented }
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(operation == "saveFile" ? false : nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    if operation == "saveFile" {
      if !extensionName.isEmpty && urls.contains(where: { !$0.lastPathComponent.lowercased().hasSuffix("." + extensionName.lowercased()) }) {
        finish(FlutterError(code: "invalid_extension", message: "The document provider changed the file extension", details: nil))
      } else {
        finish(true)
      }
    } else if operation == "pickDirectory" {
      guard let url = urls.first else { finish(nil); return }
      if url.startAccessingSecurityScopedResource() { directories.append(url) }
      if let bookmark = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) {
        var saved = UserDefaults.standard.dictionary(forKey: "lw_sysapi.directories") ?? [:]
        saved[url.path] = bookmark
        UserDefaults.standard.set(saved, forKey: "lw_sysapi.directories")
      }
      finish(url.path)
    } else {
      finish(urls.map { url -> [String: Any] in
        selectedURLs[url.path] = url
        return ["path": url.path, "name": url.lastPathComponent]
      })
    }
  }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    operation = ""
    if let temporary = temporaryURL {
      try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
    }
    temporaryURL = nil
    callback?(value)
  }
}
