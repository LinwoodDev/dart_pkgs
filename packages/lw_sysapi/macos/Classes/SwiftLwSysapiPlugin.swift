import Cocoa
import FlutterMacOS

public class SwiftLwSysapiPlugin: NSObject, FlutterPlugin {
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
    registrar.addMethodCallDelegate(SwiftLwSysapiPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
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

  private func readClipboard(types: [String]?) -> [String: Any]? {
    let requestedTypes = types ?? defaultTypes
    let pasteboard = NSPasteboard.general
    for type in requestedTypes {
      if type == "text/plain", let string = pasteboard.string(forType: .string) {
        return [
          "type": type,
          "data": FlutterStandardTypedData(bytes: Data(string.utf8)),
        ]
      }
      if type == "image/png",
        let image = NSImage(pasteboard: pasteboard),
        let data = pngData(from: image)
      {
        return ["type": type, "data": FlutterStandardTypedData(bytes: data)]
      }
      if type == "image/jpeg",
        let image = NSImage(pasteboard: pasteboard),
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

  private func pasteboardTypes(for mimeType: String) -> [String] {
    switch mimeType {
    case "text/plain":
      return ["public.utf8-plain-text", "public.plain-text", NSPasteboard.PasteboardType.string.rawValue, mimeType]
    case "text/html":
      return ["public.html", NSPasteboard.PasteboardType.html.rawValue, mimeType]
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
