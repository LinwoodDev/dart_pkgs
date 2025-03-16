#ifndef FLUTTER_PLUGIN_INPUT_LEAP_PLUGIN_H_
#define FLUTTER_PLUGIN_INPUT_LEAP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace input_leap {

class InputLeapPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  InputLeapPlugin();

  virtual ~InputLeapPlugin();

  // Disallow copy and assign.
  InputLeapPlugin(const InputLeapPlugin&) = delete;
  InputLeapPlugin& operator=(const InputLeapPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleMsg(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
};

}  // namespace input_leap

#endif  // FLUTTER_PLUGIN_INPUT_LEAP_PLUGIN_H_
