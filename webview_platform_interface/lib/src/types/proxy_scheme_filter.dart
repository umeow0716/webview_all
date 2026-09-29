// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Scheme filters used by [ProxyRule].
class ProxySchemeFilter {
  /// Creates a scheme filter with the given string [value].
  const ProxySchemeFilter._(this.value);

  /// Matches all schemes.
  static const ProxySchemeFilter matchAllSchemes = ProxySchemeFilter._('*');

  /// Matches HTTP requests.
  static const ProxySchemeFilter matchHttp = ProxySchemeFilter._('http');

  /// Matches HTTPS requests.
  static const ProxySchemeFilter matchHttps = ProxySchemeFilter._('https');

  /// All known scheme filters.
  static const Set<ProxySchemeFilter> values = <ProxySchemeFilter>{
    matchAllSchemes,
    matchHttp,
    matchHttps,
  };

  /// The string value passed through the platform channel.
  final String value;

  /// Gets a possible [ProxySchemeFilter] from a string value.
  static ProxySchemeFilter? fromValue(String? value) {
    if (value == null) {
      return null;
    }
    for (final ProxySchemeFilter filter in values) {
      if (filter.value == value) {
        return filter;
      }
    }
    return null;
  }

  /// Converts this filter to its string representation for platform messages.
  String toValue() => value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    return other is ProxySchemeFilter && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
