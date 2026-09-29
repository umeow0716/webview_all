import 'package:webview_platform_interface/webview_platform_interface.dart';

/// Manages process-wide proxy settings for WebViews.
class ProxyController {
  /// Constructs a [ProxyController].
  ProxyController()
    : this.fromPlatformCreationParams(
        const PlatformProxyControllerCreationParams(),
      );

  /// Constructs a [ProxyController] from creation params for a specific
  /// platform.
  ProxyController.fromPlatformCreationParams(
    PlatformProxyControllerCreationParams params,
  ) : this.fromPlatform(PlatformProxyController(params));

  /// Constructs a [ProxyController] from a specific platform implementation.
  ProxyController.fromPlatform(this.platform);

  /// Gets a shared [ProxyController] instance.
  static ProxyController instance() => ProxyController();

  /// Whether proxy override is supported by the current platform.
  static bool get isSupported =>
      WebViewPlatform.instance?.supportsProxyOverride ?? false;

  /// Implementation of [PlatformProxyController] for the current platform.
  final PlatformProxyController platform;

  /// Sets proxy settings for WebViews in this process.
  Future<void> setProxyOverride({required ProxySettings settings}) {
    return platform.setProxyOverride(settings: settings);
  }

  /// Clears process-wide WebView proxy settings.
  Future<void> clearProxyOverride() {
    return platform.clearProxyOverride();
  }
}
