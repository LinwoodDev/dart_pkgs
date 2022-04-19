#include "include/lnwd_pdf_renderer/lnwd_pdf_renderer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "lnwd_pdf_renderer_plugin.h"

void LnwdPdfRendererPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  lnwd_pdf_renderer::LnwdPdfRendererPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
