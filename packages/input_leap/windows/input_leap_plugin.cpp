#include "input_leap_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace input_leap
{

  // static
  void InputLeapPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "input_leap",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<InputLeapPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->RegisterTopLevelWindowProcDelegate(
        [plugin_pointer = plugin.get()](HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) -> LRESULT
        {
          plugin_pointer->HandleMsg(hwnd, message, wParam, lParam);
          return 0;
        });

    registrar->AddPlugin(std::move(plugin));
  }

  InputLeapPlugin::InputLeapPlugin() {}

  InputLeapPlugin::~InputLeapPlugin() {}

  void InputLeapPlugin::HandleMsg(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
  {
  }

  void InputLeapPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace input_leap
