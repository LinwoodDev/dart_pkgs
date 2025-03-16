#include "include/input_leap/input_leap_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "input_leap_plugin.h"

void InputLeapPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  input_leap::InputLeapPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
