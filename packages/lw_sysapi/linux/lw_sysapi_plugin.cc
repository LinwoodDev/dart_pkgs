#include "include/lw_sysapi/lw_sysapi_plugin.h"

#include <gtk/gtk.h>
#include <cstring>

struct _LwSysapiPlugin {
  GObject parent_instance;
  GWeakRef view;
  FlMethodChannel* drop_channel;
  bool drop_enabled;
};

typedef struct _LwSysapiPlugin LwSysapiPlugin;
typedef struct {
  GObjectClass parent_class;
} LwSysapiPluginClass;

G_DEFINE_TYPE(LwSysapiPlugin, lw_sysapi_plugin, g_object_get_type())

static void send_drop_event(LwSysapiPlugin* self, const char* phase,
                            double x, double y, FlValue* items = nullptr) {
  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "phase", fl_value_new_string(phase));
  fl_value_set_string_take(event, "x", fl_value_new_float(x));
  fl_value_set_string_take(event, "y", fl_value_new_float(y));
  if (items != nullptr) fl_value_set_string(event, "items", items);
  fl_method_channel_invoke_method(self->drop_channel, "dropEvent", event,
                                  nullptr, nullptr, nullptr);
}

static gboolean on_drag_motion(GtkWidget*, GdkDragContext* drag, gint x,
                               gint y, guint time, gpointer data) {
  auto* self = static_cast<LwSysapiPlugin*>(data);
  const bool accepted = self->drop_enabled &&
      (gdk_drag_context_get_actions(drag) & GDK_ACTION_COPY) != 0;
  gdk_drag_status(drag, accepted ? GDK_ACTION_COPY : static_cast<GdkDragAction>(0), time);
  if (accepted) send_drop_event(self, "hover", x, y);
  return TRUE;
}

static void on_drag_leave(GtkWidget*, GdkDragContext*, guint, gpointer data) {
  send_drop_event(static_cast<LwSysapiPlugin*>(data), "exit", 0, 0);
}

static gboolean on_drag_drop(GtkWidget* view, GdkDragContext* drag, gint,
                            gint, guint time, gpointer data) {
  auto* self = static_cast<LwSysapiPlugin*>(data);
  if (!self->drop_enabled || !(gdk_drag_context_get_actions(drag) & GDK_ACTION_COPY)) return FALSE;
  const GdkAtom target = gtk_drag_dest_find_target(view, drag, nullptr);
  if (target == GDK_NONE) return FALSE;
  gtk_drag_get_data(view, drag, target, time);
  return TRUE;
}

static void on_drag_data(GtkWidget*, GdkDragContext* drag, gint x, gint y,
                         GtkSelectionData* selection, guint, guint time,
                         gpointer data) {
  auto* self = static_cast<LwSysapiPlugin*>(data);
  const gint length = gtk_selection_data_get_length(selection);
  const guchar* bytes = gtk_selection_data_get_data(selection);
  const bool success = self->drop_enabled && bytes != nullptr && length > 0;
  if (success) {
    g_autofree gchar* type = gdk_atom_name(gtk_selection_data_get_target(selection));
    // GTK's UTF8_STRING atom is a text encoding, rather than a MIME type.
    const char* mime = std::strcmp(type, "UTF8_STRING") == 0 ? "text/plain" : type;
    g_autoptr(FlValue) content = fl_value_new_map();
    fl_value_set_string_take(content, "type", fl_value_new_string(mime));
    fl_value_set_string_take(content, "data", fl_value_new_uint8_list(bytes, length));
    g_autoptr(FlValue) representations = fl_value_new_list();
    fl_value_append(representations, content);
    g_autoptr(FlValue) item = fl_value_new_map();
    fl_value_set_string(item, "contents", representations);
    g_autoptr(FlValue) items = fl_value_new_list();
    fl_value_append(items, item);
    send_drop_event(self, "drop", x, y, items);
  }
  gtk_drag_finish(drag, success, FALSE, time);
}

static void drop_method_call_cb(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* self = static_cast<LwSysapiPlugin*>(data);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (std::strcmp(fl_method_call_get_name(call), "setEnabled") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    self->drop_enabled = args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

static FlValue* get_display_metrics(LwSysapiPlugin* self) {
  g_autoptr(FlView) view = FL_VIEW(g_weak_ref_get(&self->view));
  if (view == nullptr) return nullptr;
  GdkWindow* window = gtk_widget_get_window(GTK_WIDGET(view));
  if (window == nullptr) return nullptr;
  GdkDisplay* display = gdk_window_get_display(window);
  GdkMonitor* monitor = gdk_display_get_monitor_at_window(display, window);
  if (monitor == nullptr) return nullptr;

  const int width_mm = gdk_monitor_get_width_mm(monitor);
  const int height_mm = gdk_monitor_get_height_mm(monitor);
  const int scale = gdk_monitor_get_scale_factor(monitor);
  GdkRectangle geometry;
  gdk_monitor_get_geometry(monitor, &geometry);
  if (width_mm <= 0 || height_mm <= 0 || scale <= 0 ||
      geometry.width <= 0 || geometry.height <= 0) {
    return nullptr;
  }

  // GDK geometry is in application pixels. Use the same device-pixel mapping
  // as the Flutter view, including desktop scaling.
  FlValue* result = fl_value_new_map();
  fl_value_set_string_take(result, "dpiX",
      fl_value_new_float(geometry.width * static_cast<double>(scale) * 25.4 / width_mm));
  fl_value_set_string_take(result, "dpiY",
      fl_value_new_float(geometry.height * static_cast<double>(scale) * 25.4 / height_mm));
  g_autofree gchar* id = g_strdup_printf("%p", static_cast<void*>(monitor));
  fl_value_set_string_take(result, "displayId", fl_value_new_string(id));
  const gchar* name = gdk_monitor_get_model(monitor);
  if (name != nullptr) {
    fl_value_set_string_take(result, "name", fl_value_new_string(name));
  }
  return result;
}

static void method_call_cb(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* self = static_cast<LwSysapiPlugin*>(data);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (std::strcmp(fl_method_call_get_name(call), "getDisplayMetrics") == 0) {
    g_autoptr(FlValue) metrics = get_display_metrics(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(metrics));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

static void lw_sysapi_plugin_finalize(GObject* object) {
  auto* self = reinterpret_cast<LwSysapiPlugin*>(object);
  g_autoptr(FlView) view = FL_VIEW(g_weak_ref_get(&self->view));
  if (view != nullptr) {
    g_signal_handlers_disconnect_by_data(view, self);
    gtk_drag_dest_unset(GTK_WIDGET(view));
  }
  g_clear_object(&self->drop_channel);
  g_weak_ref_clear(&self->view);
  G_OBJECT_CLASS(lw_sysapi_plugin_parent_class)->finalize(object);
}

static void lw_sysapi_plugin_class_init(LwSysapiPluginClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = lw_sysapi_plugin_finalize;
}

static void lw_sysapi_plugin_init(LwSysapiPlugin* self) {
  g_weak_ref_init(&self->view, nullptr);
  self->drop_channel = nullptr;
  self->drop_enabled = false;
}

void lw_sysapi_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  auto* plugin = static_cast<LwSysapiPlugin*>(
      g_object_new(lw_sysapi_plugin_get_type(), nullptr));
  g_weak_ref_set(&plugin->view, fl_plugin_registrar_get_view(registrar));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), "linwood.dev/lw_sysapi",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  plugin->drop_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), "linwood.dev/lw_sysapi/drop", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->drop_channel,
      drop_method_call_cb, plugin, nullptr);
  GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(registrar));
  if (view == nullptr) {
    g_object_unref(plugin);
    return;
  }
  // Prefer actual image bytes and HTML image sources over a browser's link URL.
  const char* types[] = {"image/png", "image/jpeg", "image/webp", "image/gif", "image/svg+xml", "text/html", "text/uri-list", "UTF8_STRING", "text/plain"};
  GtkTargetList* targets = gtk_target_list_new(nullptr, 0);
  for (const char* type : types) gtk_target_list_add(targets, gdk_atom_intern(type, FALSE), 0, 0);
  gtk_drag_dest_set(view, static_cast<GtkDestDefaults>(0), nullptr, 0, GDK_ACTION_COPY);
  gtk_drag_dest_set_target_list(view, targets);
  gtk_target_list_unref(targets);
  gtk_drag_dest_set_track_motion(view, TRUE);
  g_signal_connect(view, "drag-motion", G_CALLBACK(on_drag_motion), plugin);
  g_signal_connect(view, "drag-leave", G_CALLBACK(on_drag_leave), plugin);
  g_signal_connect(view, "drag-drop", G_CALLBACK(on_drag_drop), plugin);
  g_signal_connect(view, "drag-data-received", G_CALLBACK(on_drag_data), plugin);
  g_object_unref(plugin);
}
