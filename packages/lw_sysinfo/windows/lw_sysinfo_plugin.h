#ifndef FLUTTER_PLUGIN_LW_SYSINFO_PLUGIN_H_
#define FLUTTER_PLUGIN_LW_SYSINFO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace lw_sysinfo {

class LwSysinfoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LwSysinfoPlugin();

  virtual ~LwSysinfoPlugin();

  // Disallow copy and assign.
  LwSysinfoPlugin(const LwSysinfoPlugin&) = delete;
  LwSysinfoPlugin& operator=(const LwSysinfoPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace lw_sysinfo

#endif  // FLUTTER_PLUGIN_LW_SYSINFO_PLUGIN_H_
