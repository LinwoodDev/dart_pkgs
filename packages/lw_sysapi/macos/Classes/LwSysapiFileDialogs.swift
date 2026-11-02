import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

final class LwSysapiFileDialogs {
  weak var view: NSView?
  private var pending: FlutterResult?
  private var selectedURLs: [String: URL] = [:]
  private var directories: [URL] = []

  init(view: NSView?) {
    self.view = view
    let bookmarks = UserDefaults.standard.dictionary(forKey: "lw_sysapi.directories") ?? [:]
    for (_, value) in bookmarks {
      guard let data = value as? Data else { continue }
      var stale = false
      if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
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
        do {
          let data = try Data(contentsOf: url)
          DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: data)) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "read_failed", message: error.localizedDescription, details: path))
          }
        }
      }
      return true
    }
    guard ["pickFiles", "pickDirectory", "getSavePath"].contains(call.method) else { return false }
    guard pending == nil else {
      result(FlutterError(code: "dialog_in_progress", message: "A file dialog is already open", details: nil))
      return true
    }
    let save = call.method == "getSavePath"
    let folder = call.method == "pickDirectory"
    let ext = args["extension"] as? String ?? ""
    pending = result
    let panel: NSSavePanel
    if save {
      panel = NSSavePanel()
      panel.nameFieldStringValue = args["name"] as? String ?? ""
      panel.isExtensionHidden = false
      panel.canSelectHiddenExtension = false
    } else {
      let open = NSOpenPanel()
      open.canChooseFiles = !folder
      open.canChooseDirectories = folder
      open.allowsMultipleSelection = !folder && (args["multiple"] as? Bool ?? false)
      panel = open
    }
    if let title = args["title"] as? String { panel.title = title }
    let extensions = save ? (ext.isEmpty ? [] : [ext]) : args["extensions"] as? [String] ?? []
    if !folder && !extensions.isEmpty {
      if #available(macOS 11.0, *) {
        panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
      } else {
        panel.allowedFileTypes = extensions
      }
      panel.allowsOtherFileTypes = false
    }
    present(panel) { [self] response in
      guard response == .OK else { finish(nil); return }
      if save {
        guard let url = panel.url else { finish(nil); return }
        if ext.isEmpty { finish(url.path); return }
        let suffix = "." + ext
        let corrected = url.lastPathComponent.lowercased().hasSuffix(suffix.lowercased())
            ? url : url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + suffix)
        if corrected != url && FileManager.default.fileExists(atPath: corrected.path) {
          panel.directoryURL = corrected.deletingLastPathComponent()
          panel.nameFieldStringValue = corrected.lastPathComponent
          // Re-enter the native panel so its overwrite consent covers this path.
          presentSaveAgain(panel, ext: ext)
          return
        }
        finish(corrected.path)
      } else if let open = panel as? NSOpenPanel {
        if folder {
          guard let url = open.urls.first else { finish(nil); return }
          if url.startAccessingSecurityScopedResource() { directories.append(url) }
          if let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil,
                                             relativeTo: nil) {
            var bookmarks = UserDefaults.standard.dictionary(forKey: "lw_sysapi.directories") ?? [:]
            bookmarks[url.path] = data
            UserDefaults.standard.set(bookmarks, forKey: "lw_sysapi.directories")
          }
          finish(url.path)
        } else {
          finish(open.urls.map { url -> [String: Any] in
            selectedURLs[url.path] = url
            return ["path": url.path, "name": url.lastPathComponent]
          })
        }
      }
    }
    return true
  }

  private func presentSaveAgain(_ panel: NSSavePanel, ext: String) {
    present(panel) { [self] response in
      guard response == .OK, let url = panel.url else { finish(nil); return }
      let suffix = "." + ext
      let corrected = url.lastPathComponent.lowercased().hasSuffix(suffix.lowercased())
          ? url : url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + suffix)
      if corrected != url && FileManager.default.fileExists(atPath: corrected.path) {
        panel.directoryURL = corrected.deletingLastPathComponent()
        panel.nameFieldStringValue = corrected.lastPathComponent
        presentSaveAgain(panel, ext: ext)
      } else {
        finish(corrected.path)
      }
    }
  }

  private func present(_ panel: NSSavePanel, completion: @escaping (NSApplication.ModalResponse) -> Void) {
    if let window = view?.window ?? NSApp.keyWindow {
      panel.beginSheetModal(for: window, completionHandler: completion)
    } else {
      panel.begin(completionHandler: completion)
    }
  }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    callback?(value)
  }
}
