#include "linux_file_dialogs.h"

#include <cctype>
#include <cstring>
#include <string>

namespace {
const char* string_arg(FlValue* args, const char* key) {
  FlValue* value = fl_value_lookup_string(args, key);
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
      ? fl_value_get_string(value) : nullptr;
}

void respond(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_method_call_respond(call, response, nullptr);
}

void fail(FlMethodCall* call, const char* code, const char* message) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_error_response_new(code, message, nullptr));
  fl_method_call_respond(call, response, nullptr);
}

std::string with_extension(std::string path, const std::string& extension) {
  const std::string suffix = "." + extension;
  if (path.size() >= suffix.size()) {
    std::string end = path.substr(path.size() - suffix.size());
    std::string expected = suffix;
    for (char& c : end) c = std::tolower(static_cast<unsigned char>(c));
    for (char& c : expected) c = std::tolower(static_cast<unsigned char>(c));
    if (end == expected) return path;
  }
  return path + suffix;
}

std::string pattern(const char* extension) {
  std::string result = "*.";
  for (const unsigned char c : std::string(extension)) {
    if (g_ascii_isalpha(c)) {
      result += '[';
      result += g_ascii_tolower(c);
      result += g_ascii_toupper(c);
      result += ']';
    } else {
      result += c;
    }
  }
  return result;
}

struct Request {
  FlMethodCall* call;
  GObject* owner;
  bool* busy;
  GtkFileChooserNative* dialog;
  bool save;
  bool folder;
  std::string extension;

  ~Request() {
    *busy = false;
    gtk_native_dialog_destroy(GTK_NATIVE_DIALOG(dialog));
    g_object_unref(dialog);
    g_object_unref(call);
    g_object_unref(owner);
  }
};

gboolean show_again(gpointer data) {
  auto* request = static_cast<Request*>(data);
  gtk_native_dialog_show(GTK_NATIVE_DIALOG(request->dialog));
  return G_SOURCE_REMOVE;
}

void response_cb(GtkNativeDialog*, gint response, gpointer data) {
  auto* request = static_cast<Request*>(data);
  if (response != GTK_RESPONSE_ACCEPT) {
    respond(request->call, nullptr);
    delete request;
    return;
  }
  auto* chooser = GTK_FILE_CHOOSER(request->dialog);
  if (request->save || request->folder) {
    g_autofree gchar* selected = gtk_file_chooser_get_filename(chooser);
    if (!selected) {
      fail(request->call, "invalid_path", "No local path was selected");
      delete request;
      return;
    }
    const std::string path = request->save && !request->extension.empty()
        ? with_extension(selected, request->extension) : selected;
    if (path != selected &&
        (g_file_test(path.c_str(), G_FILE_TEST_EXISTS) ||
         g_file_test(path.c_str(), G_FILE_TEST_IS_SYMLINK))) {
      // Confirm the actual target, not the extension-less name originally chosen.
      g_autofree gchar* name = g_path_get_basename(path.c_str());
      g_autofree gchar* directory = g_path_get_dirname(path.c_str());
      gtk_file_chooser_set_current_folder(chooser, directory);
      gtk_file_chooser_set_current_name(chooser, name);
      g_idle_add(show_again, request);
      return;
    }
    g_autoptr(FlValue) result = fl_value_new_string(path.c_str());
    respond(request->call, result);
  } else {
    g_autoptr(FlValue) results = fl_value_new_list();
    GSList* paths = gtk_file_chooser_get_filenames(chooser);
    for (GSList* item = paths; item; item = item->next) {
      const char* path = static_cast<char*>(item->data);
      g_autofree gchar* name = g_path_get_basename(path);
      g_autoptr(FlValue) file = fl_value_new_map();
      fl_value_set_string_take(file, "path", fl_value_new_string(path));
      fl_value_set_string_take(file, "name", fl_value_new_string(name));
      fl_value_append(results, file);
    }
    g_slist_free_full(paths, g_free);
    respond(request->call, results);
  }
  delete request;
}
}  // namespace

bool lw_sysapi_handle_file_dialog(FlMethodCall* call, GtkWindow* parent,
                                  GObject* owner, bool* busy) {
  const char* method = fl_method_call_get_name(call);
  const bool save = std::strcmp(method, "getSavePath") == 0;
  const bool folder = std::strcmp(method, "pickDirectory") == 0;
  if (!save && !folder && std::strcmp(method, "pickFiles") != 0) return false;
  FlValue* args = fl_method_call_get_args(call);
  if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    fail(call, "invalid_arguments", "Expected file dialog options");
    return true;
  }
  if (*busy) {
    fail(call, "dialog_in_progress", "A file dialog is already open");
    return true;
  }
  const char* extension = string_arg(args, "extension");
  const char* title = string_arg(args, "title");
  const auto action = save ? GTK_FILE_CHOOSER_ACTION_SAVE
      : folder ? GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER : GTK_FILE_CHOOSER_ACTION_OPEN;
  auto* dialog = gtk_file_chooser_native_new(
      title ? title : save ? "Save File" : folder ? "Select Folder" : "Open File",
      parent, action, nullptr, nullptr);
  gtk_native_dialog_set_modal(GTK_NATIVE_DIALOG(dialog), TRUE);
  auto* chooser = GTK_FILE_CHOOSER(dialog);
  gtk_file_chooser_set_local_only(chooser, TRUE);
  if (save) {
    gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
    const char* name = string_arg(args, "name");
    if (name) gtk_file_chooser_set_current_name(chooser, name);
  } else if (!folder) {
    FlValue* multiple = fl_value_lookup_string(args, "multiple");
    gtk_file_chooser_set_select_multiple(chooser, multiple &&
        fl_value_get_type(multiple) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(multiple));
  }
  FlValue* extensions = fl_value_lookup_string(args, "extensions");
  if ((save && extension && *extension) || (extensions && fl_value_get_type(extensions) == FL_VALUE_TYPE_LIST &&
               fl_value_get_length(extensions) > 0)) {
    GtkFileFilter* filter = gtk_file_filter_new();
    std::string label;
    if (save) {
      gtk_file_filter_add_pattern(filter, pattern(extension).c_str());
      label = "*." + std::string(extension);
    } else {
      for (size_t i = 0; i < fl_value_get_length(extensions); ++i) {
        FlValue* value = fl_value_get_list_value(extensions, i);
        if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) continue;
        const char* ext = fl_value_get_string(value);
        gtk_file_filter_add_pattern(filter, pattern(ext).c_str());
        label += (label.empty() ? "" : ", ") + std::string("*.") + ext;
      }
    }
    gtk_file_filter_set_name(filter, label.c_str());
    gtk_file_chooser_add_filter(chooser, filter);
  }
  *busy = true;
  auto* request = new Request{FL_METHOD_CALL(g_object_ref(call)),
      G_OBJECT(g_object_ref(owner)), busy, dialog, save, folder,
      extension ? extension : ""};
  g_signal_connect(dialog, "response", G_CALLBACK(response_cb), request);
  gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog));
  return true;
}
