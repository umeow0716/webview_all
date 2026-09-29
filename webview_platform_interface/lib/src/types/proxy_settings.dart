// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'proxy_rule.dart';

/// Settings used by [PlatformProxyController] to configure WebView proxying.
class ProxySettings {
  /// Creates [ProxySettings].
  const ProxySettings({
    this.bypassRules = const <String>[],
    this.proxyRules = const <ProxyRule>[],
  });

  /// Host patterns that should bypass the configured proxies.
  final List<String> bypassRules;

  /// Proxy rules to apply. Platform implementations may support a subset of
  /// scheme filters.
  final List<ProxyRule> proxyRules;

  /// Returns a copy of this settings object.
  ProxySettings copy() {
    return ProxySettings(
      bypassRules: List<String>.unmodifiable(bypassRules),
      proxyRules: List<ProxyRule>.unmodifiable(proxyRules),
    );
  }

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'bypassRules': bypassRules,
      'proxyRules': proxyRules.map((ProxyRule rule) => rule.toMap()).toList(),
    };
  }

  /// Converts this object to a JSON-compatible map.
  Map<String, Object?> toJson() => toMap();

  /// Gets a possible [ProxySettings] instance from a map value.
  static ProxySettings? fromMap(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final List<Object?> proxyRules =
        (map['proxyRules'] as List<Object?>?) ?? const <Object?>[];
    final List<Object?> bypassRules =
        (map['bypassRules'] as List<Object?>?) ?? const <Object?>[];
    return ProxySettings(
      bypassRules: bypassRules.whereType<String>().toList(),
      proxyRules: proxyRules
          .whereType<Map<Object?, Object?>>()
          .map(
            (Map<Object?, Object?> rule) => ProxyRule.fromMap(
              rule.cast<String, Object?>(),
            ),
          )
          .whereType<ProxyRule>()
          .toList(),
    );
  }

  @override
  String toString() => toMap().toString();
}
