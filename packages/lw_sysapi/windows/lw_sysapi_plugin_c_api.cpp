#include "include/lw_sysapi/lw_sysapi_plugin_c_api.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <shellscalingapi.h>

#include <memory>
#include <cstdint>
#include <string>
#include "drop_target.h"

namespace {

class LwSysapiPlugin : public flutter::Plugin {
 public:
  explicit LwSysapiPlugin(flutter::PluginRegistrarWindows* registrar)
      : registrar_(registrar),
        channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "linwood.dev/lw_sysapi",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const auto& call, auto result) {
          if (call.method_name() == "getDisplayMetrics") {
            result->Success(GetDisplayMetrics());
          } else {
            result->NotImplemented();
          }
        });
    drop_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "linwood.dev/lw_sysapi/drop",
        &flutter::StandardMethodCodec::GetInstance());
    if (registrar->GetView() != nullptr) {
      drop_target_ = new LwSysapiDropTarget(registrar->GetView()->GetNativeWindow(), drop_channel_.get());
    }
    drop_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      if (call.method_name() == "setEnabled") {
        const auto* enabled = call.arguments() == nullptr ? nullptr : std::get_if<bool>(call.arguments());
        if (drop_target_ != nullptr) drop_target_->SetEnabled(enabled != nullptr && *enabled);
        result->Success(flutter::EncodableValue(drop_target_ != nullptr && drop_target_->registered()));
      } else {
        result->NotImplemented();
      }
    });
  }

  ~LwSysapiPlugin() override {
    if (drop_target_ != nullptr) {
      drop_target_->Detach();
      drop_target_->Release();
    }
    drop_channel_->SetMethodCallHandler(nullptr);
    channel_->SetMethodCallHandler(nullptr);
  }

 private:
  flutter::EncodableValue GetDisplayMetrics() {
    auto* view = registrar_->GetView();
    if (view == nullptr) return flutter::EncodableValue();
    const HWND window = view->GetNativeWindow();
    const HMONITOR monitor = MonitorFromWindow(window, MONITOR_DEFAULTTONULL);
    if (monitor == nullptr) return flutter::EncodableValue();
    UINT dpi_x = 0;
    UINT dpi_y = 0;
    // RAW_DPI excludes the user's desktop UI scaling percentage.
    if (FAILED(GetDpiForMonitor(monitor, MDT_RAW_DPI, &dpi_x, &dpi_y)) ||
        dpi_x == 0 || dpi_y == 0) {
      return flutter::EncodableValue();
    }
    flutter::EncodableMap metrics = {
        {flutter::EncodableValue("dpiX"), flutter::EncodableValue(static_cast<double>(dpi_x))},
        {flutter::EncodableValue("dpiY"), flutter::EncodableValue(static_cast<double>(dpi_y))},
        {flutter::EncodableValue("displayId"), flutter::EncodableValue(
            std::to_string(reinterpret_cast<std::uintptr_t>(monitor)))},
    };
    return flutter::EncodableValue(metrics);
  }

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> drop_channel_;
  LwSysapiDropTarget* drop_target_ = nullptr;
};

}  // namespace

void LwSysapiPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  auto* windows_registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  windows_registrar->AddPlugin(std::make_unique<LwSysapiPlugin>(windows_registrar));
}
