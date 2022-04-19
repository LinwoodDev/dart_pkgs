#ifndef FLUTTER_PLUGIN_LNWD_PDF_RENDERER_PLUGIN_H_
#define FLUTTER_PLUGIN_LNWD_PDF_RENDERER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace lnwd_pdf_renderer {

class LnwdPdfRendererPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LnwdPdfRendererPlugin();

  virtual ~LnwdPdfRendererPlugin();

  // Disallow copy and assign.
  LnwdPdfRendererPlugin(const LnwdPdfRendererPlugin&) = delete;
  LnwdPdfRendererPlugin& operator=(const LnwdPdfRendererPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace lnwd_pdf_renderer

#endif  // FLUTTER_PLUGIN_LNWD_PDF_RENDERER_PLUGIN_H_
