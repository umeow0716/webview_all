# WebView All

[English Doc](https://abandoft.github.io/webview_all) | [中文文档](https://abandoft.github.io/webview_all/zh)

A WebView component for all Flutter platforms, compatible with the
[webview_flutter](https://pub.dev/packages/webview_flutter) API.

|     Platform     | **Support** | **Implementation** |
|-------------|--------------|--------------|
|Android|API 24+|[WebView](https://developer.android.com/reference/android/webkit/WebView)|
|iOS|13.0+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|macOS|10.15+|[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)|
|Windows|Win10 1809+|[WebView2](https://developer.microsoft.com/microsoft-edge/webview2)|
|Linux|webkit2gtk-4.1|[WebKitGTK](https://webkitgtk.org)|
|OHOS|API 12+|[ArkWeb](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V5/ts-basic-components-web-V5)|
|Web|Any|[js-interop](https://dart.dev/interop/js-interop)|

## Features

- Comprehensive support for all platforms
- Full compatibility with the `webview_flutter` API
- Additional features:
  - Promise-aware asynchronous JavaScript calls
  - Custom JavaScript injection before page scripts execute
  - Desktop download controls and Windows debugging and shortcut settings
  - Richer Web interactions and iframe configuration
  - Website data cleanup without a controller
  - Offscreen WebView sessions that can be explicitly closed

## Quick Start

1. Instantiate a `WebViewController`:

```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse('https://flutter.dev'));
```

2. Pass `controller` to `WebViewWidget`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: controller),
  );
}
```

## Raw request and response capture (Windows / Linux)

Windows and Linux can expose native WebView network metadata without eagerly
copying response bodies into Dart. Other platforms report
`WebResourceCaptureSupport.unsupported`.

```dart
if (controller.webResourceCaptureSupport ==
    WebResourceCaptureSupport.supported) {
  await controller.setOnRawWebResourceResponse((request, response) async {
    // On Windows this request is the committed request, including headers the
    // WebView2 network stack added after WebResourceRequested.
    if (request.headerState == WebResourceRequestHeaderState.committed) {
      final actualRequestHeaders = request.headers;
    }

    if (response.mimeType == 'application/json') {
      final bytes = await response.getContent();
      // Decode only the responses your application actually needs.
    }
  });

  await controller.setWebResourceCaptureEnabled(true);
}
```

`RawWebResourceResponse.getContent()` is asynchronous and on-demand. Request
body access is currently reported as `WebResourceContentAccess.unsupported` so
native request streams are never consumed as a side effect of observation.
On Windows, the standalone raw-request callback is captured from
`WebResourceRequested`, whose headers can still be supplemented by WebView2's
network stack, so it reports `WebResourceRequestHeaderState.provisional`. The
request supplied to the raw-response callback comes from
`WebResourceResponseReceived` and reports `WebResourceRequestHeaderState.committed`;
use that request when the actual headers sent by WebView2 are required.
On Linux, WebKitGTK exposes `WebKitWebResource::sent-request`, but WebKit emits
that signal from `dispatchWillSendRequest` before the request enters the
NetworkProcess. libsoup can still add or change transport headers afterwards,
including cookies, authentication, and defaults such as `Accept`, so both raw
callbacks report `WebResourceRequestHeaderState.provisional`. WebKitGTK does not
currently expose a public committed-request snapshot equivalent to WebView2's
response event request.
Capture can be disabled at runtime with
`setWebResourceCaptureEnabled(false)`; pending native content handles are then
released. Pending lazy-content handles are bounded, so call `getContent()` from
the capture callback when a response is worth retaining instead of holding raw
response objects indefinitely.

For detailed usage, API coverage, and platform limits, see the [Documentation](https://abandoft.github.io/webview_all).
