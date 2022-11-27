#include "include/lw_sysinfo/lw_sysinfo_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "lw_sysinfo_plugin.h"

void LwSysinfoPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  lw_sysinfo::LwSysinfoPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
