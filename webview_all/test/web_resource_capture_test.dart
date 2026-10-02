import 'package:flutter_test/flutter_test.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_platform_interface/webview_platform_interface.dart';

void main() {
  test('WebViewController forwards web resource capture controls', () async {
    final _CapturePlatformController platform = _CapturePlatformController();
    final WebViewController controller = WebViewController.fromPlatform(
      platform,
    );

    expect(
      controller.webResourceCaptureSupport,
      WebResourceCaptureSupport.supported,
    );

    RawWebResourceRequestCallback? requestCallback;
    RawWebResourceResponseCallback? responseCallback;
    await controller.setOnRawWebResourceRequest(
      requestCallback = (RawWebResourceRequest request) {},
    );
    await controller.setOnRawWebResourceResponse(
      responseCallback = (
        RawWebResourceRequest request,
        RawWebResourceResponse response,
      ) {},
    );
    await controller.setWebResourceCaptureEnabled(true);

    expect(platform.captureEnabled, isTrue);
    expect(platform.onRequest, same(requestCallback));
    expect(platform.onResponse, same(responseCallback));
  });

  test('default platform reports capture as unsupported', () async {
    final _UnsupportedCapturePlatformController platform =
        _UnsupportedCapturePlatformController();

    expect(
      platform.webResourceCaptureSupport,
      WebResourceCaptureSupport.unsupported,
    );
    await expectLater(platform.setWebResourceCaptureEnabled(false), completes);
    expect(
      () => platform.setWebResourceCaptureEnabled(true),
      throwsUnsupportedError,
    );
  });
}

class _CapturePlatformController extends PlatformWebViewController {
  _CapturePlatformController()
    : super.implementation(const PlatformWebViewControllerCreationParams());

  bool captureEnabled = false;
  RawWebResourceRequestCallback? onRequest;
  RawWebResourceResponseCallback? onResponse;

  @override
  WebResourceCaptureSupport get webResourceCaptureSupport =>
      WebResourceCaptureSupport.supported;

  @override
  Future<void> setWebResourceCaptureEnabled(bool enabled) async {
    captureEnabled = enabled;
  }

  @override
  Future<void> setOnRawWebResourceRequest(
    RawWebResourceRequestCallback? onRequest,
  ) async {
    this.onRequest = onRequest;
  }

  @override
  Future<void> setOnRawWebResourceResponse(
    RawWebResourceResponseCallback? onResponse,
  ) async {
    this.onResponse = onResponse;
  }
}

class _UnsupportedCapturePlatformController extends PlatformWebViewController {
  _UnsupportedCapturePlatformController()
    : super.implementation(const PlatformWebViewControllerCreationParams());
}
