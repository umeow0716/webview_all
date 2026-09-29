// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'proxy_scheme_filter.dart';

/// A proxy rule that maps an optional scheme filter to a proxy URL.
class ProxyRule {
  /// Creates a [ProxyRule].
  const ProxyRule({this.schemeFilter, required this.url});

  /// The optional scheme filter this rule applies to.
  final ProxySchemeFilter? schemeFilter;

  /// The proxy URL.
  final String url;

  /// Converts this rule to a platform-channel map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'schemeFilter': schemeFilter?.toValue(),
      'url': url,
    };
  }

  /// Converts this rule to a JSON-compatible map.
  Map<String, Object?> toJson() => toMap();

  /// Gets a possible [ProxyRule] instance from a map value.
  static ProxyRule? fromMap(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final Object? url = map['url'];
    if (url == null) {
      return null;
    }
    return ProxyRule(
      schemeFilter: ProxySchemeFilter.fromValue(map['schemeFilter'] as String?),
      url: url as String,
    );
  }

  @override
  String toString() => toMap().toString();

  @override
  bool operator ==(Object other) {
    return other is ProxyRule &&
        other.schemeFilter == schemeFilter &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(schemeFilter, url);
}
