//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <lnwd_pdf_renderer/lnwd_pdf_renderer_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) lnwd_pdf_renderer_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LnwdPdfRendererPlugin");
  lnwd_pdf_renderer_plugin_register_with_registrar(lnwd_pdf_renderer_registrar);
}
