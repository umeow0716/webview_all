// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'types/types.dart';
import 'webview_platform.dart' show WebViewPlatform;

/// Interface for a platform implementation that manages WebView proxy settings.
abstract class PlatformProxyController extends PlatformInterface {
  /// Creates a new [PlatformProxyController].
  factory PlatformProxyController(PlatformProxyControllerCreationParams params) {
    assert(
      WebViewPlatform.instance != null,
      'A platform implementation for `webview_all` has not been set. Please '
      'ensure that an implementation of `WebViewPlatform` has been set to '
      '`WebViewPlatform.instance` before use. For unit testing, '
      '`WebViewPlatform.instance` can be set with your own test implementation.',
    );
    final PlatformProxyController controller = WebViewPlatform.instance!
        .createPlatformProxyController(params);
    PlatformInterface.verify(controller, _token);
    return controller;
  }

  /// Used by the platform implementation to create a new
  /// [PlatformProxyController].
  @protected
  PlatformProxyController.implementation(this.params) : super(token: _token);

  static final Object _token = Object();

  /// The parameters used to initialize this [PlatformProxyController].
  final PlatformProxyControllerCreationParams params;

  /// Sets [ProxySettings] to be used by WebViews in the current process.
  Future<void> setProxyOverride({required ProxySettings settings}) {
    throw UnimplementedError(
      'setProxyOverride is not implemented on the current platform',
    );
  }

  /// Clears proxy settings for WebViews in the current process.
  Future<void> clearProxyOverride() {
    throw UnimplementedError(
      'clearProxyOverride is not implemented on the current platform',
    );
  }
}
