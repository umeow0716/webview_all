import 'package:webview_platform_interface/webview_platform_interface.dart';

import 'linux_webview_controller.dart';

/// Linux-specific creation params for [LinuxProxyController].
class LinuxProxyControllerCreationParams
    extends PlatformProxyControllerCreationParams {
  /// Creates Linux proxy controller creation params.
  const LinuxProxyControllerCreationParams();

  /// Creates Linux proxy controller creation params from platform params.
  const LinuxProxyControllerCreationParams.fromPlatformProxyControllerCreationParams(
    PlatformProxyControllerCreationParams params,
  );
}

/// Controls WebKitGTK proxy settings for Linux WebViews.
class LinuxProxyController extends PlatformProxyController {
  /// Creates a [LinuxProxyController].
  LinuxProxyController(PlatformProxyControllerCreationParams params)
    : super.implementation(
        params is LinuxProxyControllerCreationParams
            ? params
            : LinuxProxyControllerCreationParams.fromPlatformProxyControllerCreationParams(
                params,
              ),
      );

  /// Gets a Linux proxy controller instance.
  static LinuxProxyController instance() {
    return LinuxProxyController(const LinuxProxyControllerCreationParams());
  }

  @override
  Future<void> setProxyOverride({required ProxySettings settings}) {
    _validateProxySettings(settings);
    return LinuxWebViewController.rootChannel.invokeMethod<void>(
      'setProxyOverride',
      settings.toMap(),
    );
  }

  @override
  Future<void> clearProxyOverride() {
    return LinuxWebViewController.rootChannel.invokeMethod<void>(
      'clearProxyOverride',
    );
  }

  void _validateProxySettings(ProxySettings settings) {
    if (settings.proxyRules.isEmpty) {
      throw ArgumentError.value(
        settings,
        'settings',
        'At least one proxy rule is required.',
      );
    }

    for (final ProxyRule rule in settings.proxyRules) {
      if (rule.url.isEmpty) {
        throw ArgumentError.value(
          rule.url,
          'settings.proxyRules.url',
          'Proxy URL must not be empty.',
        );
      }
      final Uri uri = Uri.parse(rule.url);
      if (!uri.hasScheme || uri.host.isEmpty) {
        throw ArgumentError.value(
          rule.url,
          'settings.proxyRules.url',
          'Proxy URL must be an absolute URI with a host.',
        );
      }
      final ProxySchemeFilter? schemeFilter = rule.schemeFilter;
      if (schemeFilter != null &&
          !ProxySchemeFilter.values.contains(schemeFilter)) {
        throw ArgumentError.value(
          schemeFilter,
          'settings.proxyRules.schemeFilter',
          'Unsupported proxy scheme filter.',
        );
      }
    }
  }
}
