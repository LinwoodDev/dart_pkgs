import Flutter
import UIKit

final class LwSysapiDropDelegate: NSObject, UIDropInteractionDelegate {
  private let channel: FlutterMethodChannel
  private weak var view: UIView?
  private var enabled = false
  private var interaction: UIDropInteraction?
  private let formats = [
    ("public.png", "image/png"), ("public.jpeg", "image/jpeg"),
    ("public.svg-image", "image/svg+xml"), ("com.adobe.pdf", "application/pdf"),
    ("public.html", "text/html"), ("public.url", "text/uri-list"),
    ("public.utf8-plain-text", "text/plain"), ("public.data", "application/octet-stream"),
  ]

  init(view: UIView, channel: FlutterMethodChannel) {
    self.view = view
    self.channel = channel
    super.init()
    let interaction = UIDropInteraction(delegate: self)
    self.interaction = interaction
    view.addInteraction(interaction)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.enabled = call.arguments as? Bool ?? false
      result(true)
    }
  }

  deinit {
    if let interaction = interaction { view?.removeInteraction(interaction) }
  }

  private func send(_ phase: String, point: CGPoint, items: [[String: Any]] = []) {
    channel.invokeMethod("dropEvent", arguments: [
      "phase": phase, "x": point.x, "y": point.y, "items": items,
    ])
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    return enabled && session.items.contains { item in
      formats.contains { item.itemProvider.hasItemConformingToTypeIdentifier($0.0) }
    }
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    guard enabled, let view = view else { return UIDropProposal(operation: .forbidden) }
    send("hover", point: session.location(in: view))
    return UIDropProposal(operation: .copy)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
    send("exit", point: .zero)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
    send("exit", point: .zero)
  }

  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    guard enabled, let view = view else { return }
    let point = session.location(in: view)
    let group = DispatchGroup()
    let lock = NSLock()
    var results = Array<[String: Any]?>(repeating: nil, count: session.items.count)
    for (index, item) in session.items.enumerated() {
      let provider = item.itemProvider
      if provider.hasItemConformingToTypeIdentifier("public.file-url") {
        group.enter()
        provider.loadFileRepresentation(forTypeIdentifier: "public.data") { url, _ in
          defer { group.leave() }
          guard let url = url, let data = try? Data(contentsOf: url) else { return }
          let result: [String: Any] = [
            "name": provider.suggestedName ?? url.lastPathComponent,
            "contents": [["type": "application/octet-stream", "data": FlutterStandardTypedData(bytes: data)]],
          ]
          lock.lock()
          results[index] = result
          lock.unlock()
        }
        continue
      }
      guard let format = formats.first(where: { provider.hasItemConformingToTypeIdentifier($0.0) }) else { continue }
      group.enter()
      provider.loadDataRepresentation(forTypeIdentifier: format.0) { data, _ in
        defer { group.leave() }
        guard let data = data else { return }
        var result: [String: Any] = ["contents": [[
          "type": format.1, "data": FlutterStandardTypedData(bytes: data),
        ]]]
        // Text and URL provider names are display labels, not file names.
        if !format.1.hasPrefix("text/") { result["name"] = provider.suggestedName }
        lock.lock()
        results[index] = result
        lock.unlock()
      }
    }
    group.notify(queue: .main) {
      self.send("drop", point: point, items: results.compactMap { $0 })
    }
  }
}
