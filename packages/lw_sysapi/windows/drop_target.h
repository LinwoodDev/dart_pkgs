#pragma once

#include <windows.h>
#include <ole2.h>
#include <shellapi.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <vector>

// OLE and the clipboard expose the same data representations through IDataObject.
class LwSysapiDropTarget : public IDropTarget {
 public:
  LwSysapiDropTarget(HWND window,
      flutter::MethodChannel<flutter::EncodableValue>* channel)
      : window_(window), channel_(channel) {
    const HRESULT initialized = OleInitialize(nullptr);
    initialized_ = SUCCEEDED(initialized);
    if (initialized_) registered_ = SUCCEEDED(RegisterDragDrop(window_, this));
  }

  void SetEnabled(bool enabled) { enabled_ = enabled; }
  bool registered() const { return registered_; }
  void Detach() {
    enabled_ = false;
    if (registered_) RevokeDragDrop(window_);
    registered_ = false;
    channel_ = nullptr;
    if (initialized_) OleUninitialize();
    initialized_ = false;
  }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void** object) override {
    if (id == IID_IUnknown || id == IID_IDropTarget) {
      *object = static_cast<IDropTarget*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&references_); }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG count = InterlockedDecrement(&references_);
    if (count == 0) delete this;
    return count;
  }

  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD, POINTL point,
                                       DWORD* effect) override {
    supported_ = CanRead(data);
    return DragOver(0, point, effect);
  }
  HRESULT STDMETHODCALLTYPE DragOver(DWORD, POINTL point, DWORD* effect) override {
    const bool accept = enabled_ && supported_ && (*effect & DROPEFFECT_COPY);
    *effect = accept ? DROPEFFECT_COPY : DROPEFFECT_NONE;
    if (accept) Send("hover", point);
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE DragLeave() override {
    Send("exit", POINTL{0, 0});
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD, POINTL point,
                                  DWORD* effect) override {
    flutter::EncodableList items;
    if (enabled_ && (*effect & DROPEFFECT_COPY)) items = Read(data);
    *effect = items.empty() ? DROPEFFECT_NONE : DROPEFFECT_COPY;
    Send(items.empty() ? "exit" : "drop", point, items);
    return S_OK;
  }

 private:
  using Value = flutter::EncodableValue;
  using Map = flutter::EncodableMap;
  using List = flutter::EncodableList;

  static std::string Utf8(const std::wstring& value) {
    const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
        static_cast<int>(value.size()), nullptr, 0, nullptr, nullptr);
    std::string result(static_cast<size_t>(size), '\0');
    if (size > 0) WideCharToMultiByte(CP_UTF8, 0, value.data(),
        static_cast<int>(value.size()), result.data(), size, nullptr, nullptr);
    return result;
  }

  static bool Has(IDataObject* object, CLIPFORMAT format) {
    FORMATETC request = {format, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    return SUCCEEDED(object->QueryGetData(&request));
  }

  static bool CanRead(IDataObject* object) {
    return Has(object, CF_HDROP) || Has(object, CF_UNICODETEXT) ||
        Has(object, static_cast<CLIPFORMAT>(RegisterClipboardFormatW(L"PNG"))) ||
        Has(object, static_cast<CLIPFORMAT>(RegisterClipboardFormatW(L"HTML Format"))) ||
        Has(object, static_cast<CLIPFORMAT>(RegisterClipboardFormatW(L"UniformResourceLocatorW")));
  }

  static std::vector<uint8_t> Bytes(IDataObject* object, CLIPFORMAT format,
                                   bool wide_text = false) {
    FORMATETC request = {format, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    if (FAILED(object->GetData(&request, &medium))) return {};
    std::vector<uint8_t> result;
    if (medium.tymed == TYMED_HGLOBAL) {
      const auto* pointer = static_cast<const uint8_t*>(GlobalLock(medium.hGlobal));
      if (pointer != nullptr) {
        const size_t size = GlobalSize(medium.hGlobal);
        if (wide_text) {
          const auto* text = reinterpret_cast<const wchar_t*>(pointer);
          size_t length = 0;
          while (length < size / sizeof(wchar_t) && text[length] != L'\0') ++length;
          const std::string converted = Utf8(std::wstring(text, length));
          result.assign(converted.begin(), converted.end());
        } else {
          result.assign(pointer, pointer + size);
        }
        GlobalUnlock(medium.hGlobal);
      }
    }
    ReleaseStgMedium(&medium);
    return result;
  }

  static List Read(IDataObject* object) {
    FORMATETC request = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    List items;
    if (SUCCEEDED(object->GetData(&request, &medium))) {
      const HDROP files = static_cast<HDROP>(medium.hGlobal);
      const UINT count = DragQueryFileW(files, 0xffffffff, nullptr, 0);
      for (UINT i = 0; i < count; ++i) {
        const UINT size = DragQueryFileW(files, i, nullptr, 0);
        std::wstring path(size + 1, L'\0');
        DragQueryFileW(files, i, path.data(), size + 1);
        path.resize(size);
        items.emplace_back(Map{{Value("path"), Value(Utf8(path))}});
      }
      ReleaseStgMedium(&medium);
      if (!items.empty()) return items;
    }
    const struct { const wchar_t* format; const char* mime; bool wide; } formats[] = {
        {L"PNG", "image/png", false},
        {L"image/png", "image/png", false},
        {L"image/jpeg", "image/jpeg", false},
        {L"HTML Format", "text/html", false},
        {L"UniformResourceLocatorW", "text/uri-list", true},
        {nullptr, "text/plain", true},
    };
    List representations;
    for (const auto& entry : formats) {
      const CLIPFORMAT format = static_cast<CLIPFORMAT>(entry.format == nullptr
          ? CF_UNICODETEXT : RegisterClipboardFormatW(entry.format));
      auto bytes = Bytes(object, format, entry.wide);
      if (!bytes.empty()) representations.emplace_back(Map{
          {Value("type"), Value(entry.mime)}, {Value("data"), Value(bytes)}});
      // A bitmap representation already contains the complete image.
      if (!bytes.empty() && std::string(entry.mime).rfind("image/", 0) == 0) break;
    }
    if (!representations.empty()) items.emplace_back(Map{
        {Value("contents"), Value(representations)}});
    return items;
  }

  void Send(const char* phase, POINTL point, const List& items = {}) {
    if (channel_ == nullptr) return;
    POINT local = {point.x, point.y};
    ScreenToClient(window_, &local);
    const UINT dpi = GetDpiForWindow(window_);
    const double scale = dpi > 0 ? dpi / 96.0 : 1.0;
    channel_->InvokeMethod("dropEvent", std::make_unique<Value>(Map{
        {Value("phase"), Value(phase)},
        {Value("x"), Value(local.x / scale)},
        {Value("y"), Value(local.y / scale)},
        {Value("items"), Value(items)},
    }));
  }

  LONG references_ = 1;
  HWND window_;
  flutter::MethodChannel<Value>* channel_;
  bool initialized_ = false;
  bool registered_ = false;
  bool enabled_ = false;
  bool supported_ = false;
};
