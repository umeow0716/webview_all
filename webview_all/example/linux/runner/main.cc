#include "my_application.h"

#include <webview_all_linux/webview_all_linux_plugin.h>

int main(int argc, char** argv) {
  if (webview_all_linux_host_requires_early_renderer_workaround()) {
    webview_all_linux_host_apply_early_renderer_workaround();
  }

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
