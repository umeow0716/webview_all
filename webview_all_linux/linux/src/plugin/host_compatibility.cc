#include "plugin/host_compatibility.h"

#include "webview_all_linux/webview_all_linux_plugin.h"

#include <webkit2/webkit2.h>

namespace {

gboolean environment_flag_enabled(const gchar *name) {
  const gchar *value = g_getenv(name);
  if (value == nullptr || *value == '\0') {
    return FALSE;
  }
  return g_ascii_strcasecmp(value, "0") != 0 &&
         g_ascii_strcasecmp(value, "false") != 0 &&
         g_ascii_strcasecmp(value, "off") != 0 &&
         g_ascii_strcasecmp(value, "no") != 0;
}

gboolean has_nvidia_proprietary_driver() {
  return g_file_test("/proc/driver/nvidia/version", G_FILE_TEST_IS_REGULAR) ||
         g_file_test("/sys/module/nvidia/version", G_FILE_TEST_IS_REGULAR);
}

}  // namespace

LinuxHostCompatibilityInfo get_linux_host_compatibility() {
  LinuxHostCompatibilityInfo info{};
  info.webkit_major = webkit_get_major_version();
  info.webkit_minor = webkit_get_minor_version();
  info.webkit_micro = webkit_get_micro_version();
  info.nvidia_proprietary_driver_detected = has_nvidia_proprietary_driver();
  info.legacy_disable_dmabuf_renderer_requested =
      environment_flag_enabled("WEBKIT_DISABLE_DMABUF_RENDERER");
  info.requires_early_renderer_workaround =
      info.webkit_major == 2 && info.webkit_minor == 52 &&
      (info.nvidia_proprietary_driver_detected ||
       info.legacy_disable_dmabuf_renderer_requested);
  info.early_renderer_workaround_active =
      environment_flag_enabled("WEBKIT_FORCE_DMABUF_RENDERER") &&
      environment_flag_enabled("WEBKIT_DMABUF_RENDERER_FORCE_SHM") &&
      !environment_flag_enabled("WEBKIT_DISABLE_DMABUF_RENDERER");
  return info;
}

gboolean webview_all_linux_host_requires_early_renderer_workaround() {
  return get_linux_host_compatibility().requires_early_renderer_workaround;
}

void webview_all_linux_host_apply_early_renderer_workaround() {
  const LinuxHostCompatibilityInfo info = get_linux_host_compatibility();
  if (!info.requires_early_renderer_workaround) {
    return;
  }

  // This must run from the host's main() before creating the GtkApplication or
  // registering Flutter plugins. WebKitGTK caches the renderer transport mode
  // on first use, so changing these variables from a controller constructor is
  // too late on affected hosts.
  if (info.legacy_disable_dmabuf_renderer_requested) {
    g_unsetenv("WEBKIT_DISABLE_DMABUF_RENDERER");
  }
  g_setenv("WEBKIT_FORCE_DMABUF_RENDERER", "1", TRUE);
  g_setenv("WEBKIT_DMABUF_RENDERER_FORCE_SHM", "1", TRUE);
}

gboolean webview_all_linux_host_early_renderer_workaround_is_active() {
  return get_linux_host_compatibility().early_renderer_workaround_active;
}
