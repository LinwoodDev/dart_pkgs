#include "include/lw_sysapi/lw_sysapi_plugin.h"

#include <gtk/gtk.h>
#include <cstring>

struct _LwSysapiPlugin {
  GObject parent_instance;
  GWeakRef view;
};

typedef struct _LwSysapiPlugin LwSysapiPlugin;
typedef struct {
  GObjectClass parent_class;
} LwSysapiPluginClass;

G_DEFINE_TYPE(LwSysapiPlugin, lw_sysapi_plugin, g_object_get_type())

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
  g_weak_ref_clear(&self->view);
  G_OBJECT_CLASS(lw_sysapi_plugin_parent_class)->finalize(object);
}

static void lw_sysapi_plugin_class_init(LwSysapiPluginClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = lw_sysapi_plugin_finalize;
}

static void lw_sysapi_plugin_init(LwSysapiPlugin* self) {
  g_weak_ref_init(&self->view, nullptr);
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
  g_object_unref(plugin);
}
