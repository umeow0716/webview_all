# webview_all_linux

This package is part of [`webview_all`](https://github.com/abandoft/webview_all).

Use [`webview_all`](https://pub.dev/packages/webview_all) directly in your application. Do not depend on this platform implementation package directly.

## Linux host startup compatibility

Some Debian/Ubuntu WebKitGTK 2.52.x builds can crash in accelerated
compositing on systems using the proprietary NVIDIA driver. The workaround
must be applied before GTK/WebKit initialization; setting the environment from
a WebView controller or Flutter method call is too late.

Add the host check to `linux/runner/main.cc` before `my_application_new()`:

```cpp
#include "my_application.h"

#include <webview_all_linux/webview_all_linux_plugin.h>

int main(int argc, char** argv) {
  if (webview_all_linux_host_requires_early_renderer_workaround()) {
    webview_all_linux_host_apply_early_renderer_workaround();
  }

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
```

The check is a no-op on unaffected hosts. For runtime diagnostics after Flutter
has started, use:

```dart
final compatibility = await LinuxWebViewPlatform.getHostCompatibility();
print(compatibility.webKitGtkVersion);
print(compatibility.hostInitializationRequired);
print(compatibility.earlyRendererWorkaroundActive);
```

`getHostCompatibility()` is diagnostic only; it intentionally does not change
the renderer environment because WebKitGTK may already have cached it.
