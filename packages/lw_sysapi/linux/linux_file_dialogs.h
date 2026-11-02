#pragma once
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

bool lw_sysapi_handle_file_dialog(FlMethodCall* call, GtkWindow* parent,
                                  GObject* owner, bool* busy);
