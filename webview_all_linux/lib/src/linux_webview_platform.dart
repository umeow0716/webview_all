import 'package:flutter/services.dart';
import 'package:webview_platform_interface/webview_platform_interface.dart';

import 'linux_host_compatibility.dart';
import 'linux_navigation_delegate.dart';
import 'linux_proxy_controller.dart';
import 'linux_webview_constants.dart';
import 'linux_webview_controller.dart';
import 'linux_webview_cookie_manager.dart';
import 'linux_webview_data_manager.dart';
import 'linux_webview_widget.dart';

class LinuxWebViewPlatform extends WebViewPlatform {
  static const MethodChannel _rootChannel = MethodChannel(
    linuxWebViewChannelPrefix,
  );

  /// Returns WebKitGTK host compatibility diagnostics.
  ///
  /// This method is diagnostic only. If [LinuxHostCompatibility]
  /// reports [LinuxHostCompatibility.hostInitializationRequired] as true,
  /// the native host must apply the workaround from `linux/runner/main.cc`
  /// before creating the GtkApplication. Calling this method is too late to
  /// change WebKitGTK's renderer initialization safely.
  static Future<LinuxHostCompatibility> getHostCompatibility() async {
    final Map<Object?, Object?>? result =
        await _rootChannel.invokeMapMethod<Object?, Object?>(
          'getHostCompatibility',
        );
    if (result == null) {
      throw StateError('Linux host compatibility information is unavailable.');
    }
    return LinuxHostCompatibility.fromMap(result);
  }

  @override
  bool get supportsOffscreenWebViews => true;

  @override
  bool get supportsProxyOverride => true;

  static void registerWith() {
    WebViewPlatform.instance = LinuxWebViewPlatform();
  }

  @override
  LinuxWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return LinuxWebViewController(params);
  }

  @override
  LinuxNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return LinuxNavigationDelegate(params);
  }

  @override
  LinuxWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return LinuxWebViewWidget(params);
  }

  @override
  LinuxWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return LinuxWebViewCookieManager(params);
  }


  @override
  LinuxProxyController createPlatformProxyController(
    PlatformProxyControllerCreationParams params,
  ) {
    return LinuxProxyController(params);
  }

  @override
  LinuxWebViewDataManager createPlatformWebViewDataManager(
    PlatformWebViewDataManagerCreationParams params,
  ) {
    return LinuxWebViewDataManager(params);
  }
}
