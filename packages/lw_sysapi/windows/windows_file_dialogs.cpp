#include "windows_file_dialogs.h"
#include <shobjidl.h>
#include <wrl/client.h>
#include <cwctype>
#include <string>
#include <vector>

namespace {
using flutter::EncodableValue;
using flutter::EncodableMap;
using flutter::EncodableList;
using Microsoft::WRL::ComPtr;

const EncodableValue* Arg(const EncodableMap& map, const char* name) {
  const auto found = map.find(EncodableValue(name));
  return found == map.end() ? nullptr : &found->second;
}
std::wstring Wide(const std::string& text) {
  const int length = MultiByteToWideChar(CP_UTF8, 0, text.data(),
      static_cast<int>(text.size()), nullptr, 0);
  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), result.data(), length);
  return result;
}
std::string Utf8(const std::wstring& text) {
  const int length = WideCharToMultiByte(CP_UTF8, 0, text.data(),
      static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
  std::string result(length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
      result.data(), length, nullptr, nullptr);
  return result;
}
std::wstring StringArg(const EncodableMap& map, const char* name) {
  const auto* value = Arg(map, name);
  const auto* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? Wide(*text) : L"";
}
std::wstring WithExtension(const std::wstring& path, const std::wstring& extension) {
  const auto suffix = L"." + extension;
  if (path.size() >= suffix.size() && _wcsicmp(
      path.c_str() + path.size() - suffix.size(), suffix.c_str()) == 0) return path;
  return path + suffix;
}
bool ItemPath(IShellItem* item, std::wstring* path) {
  PWSTR raw = nullptr;
  if (FAILED(item->GetDisplayName(SIGDN_FILESYSPATH, &raw))) return false;
  *path = raw;
  CoTaskMemFree(raw);
  return true;
}
EncodableValue FileValue(const std::wstring& path) {
  const auto name = path.substr(path.find_last_of(L"\\/") + 1);
  return EncodableValue(EncodableMap{
      {EncodableValue("path"), EncodableValue(Utf8(path))},
      {EncodableValue("name"), EncodableValue(Utf8(name))}});
}
}  // namespace

void LwSysapiFileDialog(const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result, HWND owner) {
  const auto* args = call.arguments() ? std::get_if<EncodableMap>(call.arguments()) : nullptr;
  if (!args) { result->Error("invalid_arguments", "Expected file dialog options"); return; }
  const bool save = call.method_name() == "getSavePath";
  const bool folder = call.method_name() == "pickDirectory";
  const auto extension = StringArg(*args, "extension");
  const HRESULT initialized = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(initialized)) { result->Error("dialog_failed", "Cannot initialize the native file dialog"); return; }
  struct Apartment { ~Apartment() { CoUninitialize(); } } apartment;
  ComPtr<IFileDialog> dialog;
  HRESULT hr = save
      ? CoCreateInstance(CLSID_FileSaveDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog))
      : CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(hr)) { result->Error("dialog_failed", "Cannot create the native file dialog"); return; }
  FILEOPENDIALOGOPTIONS options = 0;
  dialog->GetOptions(&options);
  options |= FOS_FORCEFILESYSTEM | FOS_NOCHANGEDIR;
  bool multiple = false;
  if (const auto* value = Arg(*args, "multiple")) {
    if (const auto* flag = std::get_if<bool>(value)) multiple = *flag;
  }
  if (folder) options |= FOS_PICKFOLDERS;
  else if (save) options |= FOS_OVERWRITEPROMPT | FOS_PATHMUSTEXIST;
  else options |= FOS_FILEMUSTEXIST | (multiple ? FOS_ALLOWMULTISELECT : 0);
  dialog->SetOptions(options);
  const auto title = StringArg(*args, "title");
  if (!title.empty()) dialog->SetTitle(title.c_str());
  std::vector<std::wstring> extensions;
  if (save) { if (!extension.empty()) extensions.push_back(extension); }
  else if (const auto* value = Arg(*args, "extensions")) {
    if (const auto* list = std::get_if<EncodableList>(value)) {
      for (const auto& entry : *list) {
        if (const auto* text = std::get_if<std::string>(&entry)) extensions.push_back(Wide(*text));
      }
    }
  }
  std::wstring patterns;
  for (const auto& ext : extensions) {
    if (!patterns.empty()) patterns += L";";
    patterns += L"*." + ext;
  }
  if (!folder && !patterns.empty()) {
    COMDLG_FILTERSPEC filter{patterns.c_str(), patterns.c_str()};
    dialog->SetFileTypes(1, &filter);
    if (save) dialog->SetDefaultExtension(extension.c_str());
  }
  const auto name = StringArg(*args, "name");
  if (!name.empty()) dialog->SetFileName(name.c_str());
  while (true) {
    hr = dialog->Show(owner);
    if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) { result->Success(); return; }
    if (FAILED(hr)) { result->Error("dialog_failed", "The native file dialog failed"); return; }
    if (save || folder) {
      ComPtr<IShellItem> item;
      std::wstring path;
      if (FAILED(dialog->GetResult(&item)) || !ItemPath(item.Get(), &path)) {
        result->Error("invalid_path", "No local path was selected"); return;
      }
      const auto corrected = save && !extension.empty() ? WithExtension(path, extension) : path;
      if (corrected != path && GetFileAttributesW(corrected.c_str()) != INVALID_FILE_ATTRIBUTES) {
        const auto directory = corrected.substr(0, corrected.find_last_of(L"\\/"));
        const auto corrected_name = corrected.substr(corrected.find_last_of(L"\\/") + 1);
        ComPtr<IShellItem> parent;
        if (SUCCEEDED(SHCreateItemFromParsingName(directory.c_str(), nullptr, IID_PPV_ARGS(&parent)))) {
          dialog->SetFolder(parent.Get());
        }
        dialog->SetFileName(corrected_name.c_str());
        continue;
      }
      result->Success(EncodableValue(Utf8(corrected)));
      return;
    }
    ComPtr<IFileOpenDialog> open;
    ComPtr<IShellItemArray> items;
    if (FAILED(dialog.As(&open)) || FAILED(open->GetResults(&items))) {
      result->Error("invalid_path", "Cannot read the selected files"); return;
    }
    DWORD count = 0;
    items->GetCount(&count);
    EncodableList files;
    for (DWORD i = 0; i < count; ++i) {
      ComPtr<IShellItem> item;
      std::wstring path;
      if (FAILED(items->GetItemAt(i, &item)) || !ItemPath(item.Get(), &path)) {
        result->Error("invalid_path", "Cannot access the selected file"); return;
      }
      files.push_back(FileValue(path));
    }
    result->Success(EncodableValue(files));
    return;
  }
}
