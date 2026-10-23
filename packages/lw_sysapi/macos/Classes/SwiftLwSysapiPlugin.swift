import Cocoa
import FlutterMacOS

public class SwiftLwSysapiPlugin: NSObject, FlutterPlugin {
  private weak var view: NSView?
  private var dropView: LwSysapiDropView?

  deinit { dropView?.removeFromSuperview() }

  private let defaultTypes = [
    "image/png", "image/jpeg", "image/gif", "image/webp", "image/tiff",
    "image/bmp", "image/svg+xml", "application/pdf", "text/plain",
    "text/html", "application/json", "text/csv", "application/rtf",
    "application/zip", "application/gzip", "application/x-tar",
    "application/x-7z-compressed", "image/x-icon", "image/heic",
    "image/heif", "image/avif", "audio/mpeg", "audio/wav", "video/mp4",
    "video/webm",
  ]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "linwood.dev/lw_sysapi",
      binaryMessenger: registrar.messenger
    )
    let plugin = SwiftLwSysapiPlugin()
    plugin.view = registrar.view
    registrar.addMethodCallDelegate(plugin, channel: channel)
    let dropChannel = FlutterMethodChannel(name: "linwood.dev/lw_sysapi/drop", binaryMessenger: registrar.messenger)
    if let view = registrar.view {
      let dropView = LwSysapiDropView(frame: view.bounds, channel: dropChannel) { [weak plugin] pasteboard in
        plugin?.readClipboard(types: ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml", "text/html", "text/uri-list", "text/plain"], pasteboard: pasteboard, allowFileImages: false)
      }
      dropView.autoresizingMask = [.width, .height]
      view.addSubview(dropView)
      plugin.dropView = dropView
    }
    dropChannel.setMethodCallHandler { [weak plugin] call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      plugin?.dropView?.dropEnabled = call.arguments as? Bool ?? false
      result(plugin?.dropView != nil)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDisplayMetrics":
      result(getDisplayMetrics())
    case "writeClipboard":
      guard
        let arguments = call.arguments as? [String: Any],
        let type = arguments["type"] as? String,
        let data = (arguments["data"] as? FlutterStandardTypedData)?.data
      else {
        result(false)
        return
      }
      result(writeClipboard(type: type, data: data))
    case "readClipboard":
      let arguments = call.arguments as? [String: Any]
      result(readClipboard(types: arguments?["types"] as? [String]))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getDisplayMetrics() -> [String: Any]? {
    guard
      let screen = view?.window?.screen,
      let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    else { return nil }
    let displayId = CGDirectDisplayID(number.uint32Value)
    var millimeters = CGDisplayScreenSize(displayId)
    // EDID dimensions describe the panel's native orientation.
    let rotation = Int(CGDisplayRotation(displayId).rounded()) % 180
    if rotation != 0 {
      millimeters = CGSize(width: millimeters.height, height: millimeters.width)
    }
    guard millimeters.width > 0, millimeters.height > 0 else { return nil }
    // Use the pixel coordinates rendered by this view, including scaled modes.
    let pixels = screen.convertRectToBacking(screen.frame).size
    guard pixels.width > 0, pixels.height > 0 else { return nil }
    return [
      "dpiX": pixels.width * 25.4 / millimeters.width,
      "dpiY": pixels.height * 25.4 / millimeters.height,
      "displayId": String(displayId),
      "name": screen.localizedName,
    ]
  }

  private func writeClipboard(type: String, data: Data) -> Bool {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    if type == "text/plain" {
      return pasteboard.setString(
        String(data: data, encoding: .utf8) ?? "",
        forType: .string
      )
    }
    if (type == "image/png" || type == "image/jpeg"), let image = NSImage(data: data) {
      pasteboard.writeObjects([image])
    }
    var wrote = false
    for pasteboardType in pasteboardTypes(for: type) {
      wrote = pasteboard.setData(data, forType: NSPasteboard.PasteboardType(pasteboardType)) || wrote
    }
    return wrote
  }

  private func readClipboard(types: [String]?, pasteboard: NSPasteboard = .general, allowFileImages: Bool = true) -> [String: Any]? {
    let requestedTypes = types ?? defaultTypes
    for type in requestedTypes {
      if type == "text/plain", let string = pasteboard.string(forType: .string) {
        return [
          "type": type,
          "data": FlutterStandardTypedData(bytes: Data(string.utf8)),
        ]
      }
      if type == "image/png",
        let image = pasteboardImage(pasteboard, allowFileImages: allowFileImages),
        let data = pngData(from: image)
      {
        return ["type": type, "data": FlutterStandardTypedData(bytes: data)]
      }
      if type == "image/jpeg",
        let image = pasteboardImage(pasteboard, allowFileImages: allowFileImages),
        let data = jpegData(from: image)
      {
        return ["type": type, "data": FlutterStandardTypedData(bytes: data)]
      }
      for pasteboardType in pasteboardTypes(for: type) {
        if let data = pasteboard.data(forType: NSPasteboard.PasteboardType(pasteboardType)) {
          return ["type": type, "data": FlutterStandardTypedData(bytes: data)]
        }
      }
    }
    return nil
  }

  private func pasteboardImage(_ pasteboard: NSPasteboard, allowFileImages: Bool) -> NSImage? {
    if allowFileImages { return NSImage(pasteboard: pasteboard) }
    // Drops must not let NSImage implicitly resolve a pasteboard file/URL.
    for type in [NSPasteboard.PasteboardType.png, .tiff, .pdf, NSPasteboard.PasteboardType("public.jpeg")] {
      if let data = pasteboard.data(forType: type), let image = NSImage(data: data) { return image }
    }
    return nil
  }

  private func pasteboardTypes(for mimeType: String) -> [String] {
    switch mimeType {
    case "text/plain":
      return ["public.utf8-plain-text", "public.plain-text", NSPasteboard.PasteboardType.string.rawValue, mimeType]
    case "text/html":
      return ["public.html", NSPasteboard.PasteboardType.html.rawValue, mimeType]
    case "text/uri-list":
      return [NSPasteboard.PasteboardType.URL.rawValue, mimeType]
    case "image/png":
      return ["public.png", NSPasteboard.PasteboardType.png.rawValue, mimeType]
    case "image/jpeg":
      return ["public.jpeg", "public.jpg", mimeType]
    case "image/gif":
      return ["com.compuserve.gif", mimeType]
    case "image/webp":
      return ["org.webmproject.webp", mimeType]
    case "image/tiff":
      return ["public.tiff", NSPasteboard.PasteboardType.tiff.rawValue, mimeType]
    case "image/bmp":
      return ["com.microsoft.bmp", "com.microsoft.ico", mimeType]
    case "image/svg+xml":
      return ["public.svg-image", "public.svg", mimeType]
    case "application/pdf":
      return ["com.adobe.pdf", NSPasteboard.PasteboardType.pdf.rawValue, mimeType]
    case "application/json":
      return ["public.json", mimeType]
    case "text/csv":
      return ["public.comma-separated-values-text", mimeType]
    case "application/rtf":
      return ["public.rtf", "text/rtf", NSPasteboard.PasteboardType.rtf.rawValue, mimeType]
    case "application/zip":
      return ["public.zip-archive", "com.pkware.zip-archive", mimeType]
    case "application/gzip":
      return ["org.gnu.gnu-zip-archive", mimeType]
    case "application/x-tar":
      return ["public.tar-archive", mimeType]
    case "application/x-7z-compressed":
      return ["org.7-zip.7-zip-archive", mimeType]
    case "image/x-icon":
      return ["com.microsoft.ico", mimeType]
    case "image/heic":
      return ["public.heic", mimeType]
    case "image/heif":
      return ["public.heif", mimeType]
    case "image/avif":
      return ["public.avif", mimeType]
    case "audio/mpeg":
      return ["public.mp3", "public.mpeg-4-audio", mimeType]
    case "audio/wav":
      return ["com.microsoft.waveform-audio", "public.wav", mimeType]
    case "video/mp4":
      return ["public.mpeg-4", mimeType]
    case "video/webm":
      return ["org.webmproject.webm", mimeType]
    default:
      return [mimeType]
    }
  }

  private func pngData(from image: NSImage) -> Data? {
    guard
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff)
    else {
      return nil
    }
    return bitmap.representation(using: .png, properties: [:])
  }

  private func jpegData(from image: NSImage) -> Data? {
    guard
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff)
    else {
      return nil
    }
    return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 1.0])
  }
}

private class LwSysapiDropView: NSView {
  var dropEnabled = false
  private let channel: FlutterMethodChannel
  private let readContent: (NSPasteboard) -> [String: Any]?

  init(frame: NSRect, channel: FlutterMethodChannel,
       readContent: @escaping (NSPasteboard) -> [String: Any]?) {
    self.channel = channel
    self.readContent = readContent
    super.init(frame: frame)
    registerForDraggedTypes([.fileURL, .URL, .png, .tiff, .html, .string])
  }

  required init?(coder: NSCoder) { return nil }

  // The overlay handles OS drops while ordinary mouse events reach Flutter.
  override func hitTest(_ point: NSPoint) -> NSView? { return nil }

  private func send(_ phase: String, _ sender: NSDraggingInfo?, items: [[String: Any]] = []) {
    let point = convert(sender?.draggingLocation ?? .zero, from: nil)
    channel.invokeMethod("dropEvent", arguments: [
      "phase": phase, "x": point.x, "y": bounds.height - point.y, "items": items,
    ])
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    return draggingUpdated(sender)
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    guard dropEnabled && sender.draggingSourceOperationMask.contains(.copy) else { return [] }
    send("hover", sender)
    return .copy
  }

  override func draggingExited(_ sender: NSDraggingInfo?) { send("exit", sender) }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard dropEnabled && sender.draggingSourceOperationMask.contains(.copy) else { return false }
    let pasteboard = sender.draggingPasteboard
    let urls = pasteboard.readObjects(forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    if !urls.isEmpty {
      // Resolve sandbox grants and read while the drag's access is still valid.
      let point = convert(sender.draggingLocation, from: nil)
      DispatchQueue.global(qos: .userInitiated).async {
        let items: [[String: Any]] = urls.compactMap { url in
          let scoped = url.startAccessingSecurityScopedResource()
          defer { if scoped { url.stopAccessingSecurityScopedResource() } }
          guard let data = try? Data(contentsOf: url) else { return nil }
          return ["name": url.lastPathComponent, "contents": [[
            "type": "application/octet-stream", "data": FlutterStandardTypedData(bytes: data),
          ]]]
        }
        DispatchQueue.main.async {
          self.channel.invokeMethod("dropEvent", arguments: [
            "phase": "drop", "x": point.x, "y": self.bounds.height - point.y, "items": items,
          ])
        }
      }
      return true
    }
    guard let content = readContent(pasteboard) else { return false }
    send("drop", sender, items: [["contents": [content]]])
    return true
  }
}
