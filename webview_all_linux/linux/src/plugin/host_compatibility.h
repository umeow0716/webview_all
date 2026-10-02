#ifndef WEBVIEW_ALL_LINUX_HOST_COMPATIBILITY_H_
#define WEBVIEW_ALL_LINUX_HOST_COMPATIBILITY_H_

#include <glib.h>

struct LinuxHostCompatibilityInfo {
  guint webkit_major;
  guint webkit_minor;
  guint webkit_micro;
  gboolean nvidia_proprietary_driver_detected;
  gboolean legacy_disable_dmabuf_renderer_requested;
  gboolean requires_early_renderer_workaround;
  gboolean early_renderer_workaround_active;
};

LinuxHostCompatibilityInfo get_linux_host_compatibility();

#endif  // WEBVIEW_ALL_LINUX_HOST_COMPATIBILITY_H_
