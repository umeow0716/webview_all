#ifndef FLUTTER_PLUGIN_WEBVIEW_ALL_LINUX_PLUGIN_H_
#define FLUTTER_PLUGIN_WEBVIEW_ALL_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _WebviewAllLinuxPlugin WebviewAllLinuxPlugin;
typedef struct {
  GObjectClass parent_class;
} WebviewAllLinuxPluginClass;

FLUTTER_PLUGIN_EXPORT GType webview_all_linux_plugin_get_type();
FLUTTER_PLUGIN_EXPORT void webview_all_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

// Returns whether this host is affected by the WebKitGTK 2.52.x renderer
// transport bug that must be worked around before WebKit/GTK initialization.
FLUTTER_PLUGIN_EXPORT gboolean
webview_all_linux_host_requires_early_renderer_workaround();

// Applies the early renderer workaround when required. Call this from the
// application's main() before creating the GtkApplication or registering
// Flutter plugins. It is a no-op on unaffected hosts.
FLUTTER_PLUGIN_EXPORT void
webview_all_linux_host_apply_early_renderer_workaround();

// Returns whether the required renderer environment is currently active.
FLUTTER_PLUGIN_EXPORT gboolean
webview_all_linux_host_early_renderer_workaround_is_active();

G_END_DECLS

#endif  // FLUTTER_PLUGIN_WEBVIEW_ALL_LINUX_PLUGIN_H_
