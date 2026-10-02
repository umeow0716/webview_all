// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'web_resource_request.dart';
import 'web_resource_response.dart';

/// Describes whether raw web resource capture is available on the platform.
enum WebResourceCaptureSupport {
  /// The current platform does not expose raw request/response capture.
  unsupported,

  /// The current platform exposes raw request/response metadata capture.
  supported,
}

/// Describes whether the body of a captured resource can be read lazily.
enum WebResourceContentAccess {
  /// The native WebView API does not expose this resource body.
  unsupported,

  /// The body can be fetched asynchronously on demand.
  onDemand,
}

/// Describes whether captured request headers are final for network delivery.
enum WebResourceRequestHeaderState {
  /// The native WebView API does not document whether later headers can be
  /// added after this snapshot.
  unknown,

  /// The headers were captured before the native network stack finalized the
  /// request and may omit headers added later, such as authentication headers.
  provisional,

  /// The headers represent the committed request after native network-stack
  /// additions.
  committed,
}

/// A captured request emitted directly from the platform WebView network API.
///
/// Metadata is delivered eagerly. [getContent] is intentionally lazy so the
/// body only crosses the platform boundary when the application asks for it.
@immutable
abstract class RawWebResourceRequest extends WebResourceRequest {
  /// Used by platform implementations to create a raw request.
  const RawWebResourceRequest({
    required super.uri,
    required this.method,
    required this.headers,
    required this.contentAccess,
    this.headerState = WebResourceRequestHeaderState.unknown,
    this.isForMainFrame,
  });

  /// HTTP method reported by the native WebView, when available.
  final String? method;

  /// HTTP headers reported by the native WebView.
  final Map<String, String> headers;

  /// Whether [headers] are provisional or represent the committed request.
  ///
  /// For example, WebView2's `WebResourceRequested` request can be missing
  /// headers that its network stack adds later. The request paired with
  /// `WebResourceResponseReceived` is committed and includes those additions.
  final WebResourceRequestHeaderState headerState;

  /// Whether this request belongs to the main frame, when the native API
  /// exposes that information.
  final bool? isForMainFrame;

  /// Whether [getContent] is supported for this request.
  final WebResourceContentAccess contentAccess;

  /// Reads the request body asynchronously.
  ///
  /// Implementations should avoid consuming a native request stream that is
  /// still needed by the WebView. If a safe copy cannot be made, this method
  /// throws [UnsupportedError].
  Future<Uint8List?> getContent();
}

/// A captured response emitted directly from the platform WebView network API.
///
/// Metadata is delivered eagerly. [getContent] is intentionally lazy so an
/// application can inspect [headers] before deciding whether to copy the body
/// into Dart.
@immutable
abstract class RawWebResourceResponse extends WebResourceResponse {
  /// Used by platform implementations to create a raw response.
  const RawWebResourceResponse({
    required super.uri,
    required super.statusCode,
    required super.headers,
    required this.contentAccess,
    this.mimeType,
    this.reasonPhrase,
    this.contentLength,
  });

  /// MIME type reported by the native WebView, when available.
  final String? mimeType;

  /// HTTP reason phrase reported by the native WebView, when available.
  final String? reasonPhrase;

  /// Response content length reported by the native WebView, when available.
  final int? contentLength;

  /// Whether [getContent] is supported for this response.
  final WebResourceContentAccess contentAccess;

  /// Reads the response body asynchronously on demand.
  Future<Uint8List?> getContent();
}

/// Called when the native WebView reports a captured request.
///
/// Check [RawWebResourceRequest.headerState] before treating
/// [RawWebResourceRequest.headers] as the final headers sent over the network.
typedef RawWebResourceRequestCallback =
    void Function(RawWebResourceRequest request);

/// Called when the native WebView receives a captured response.
///
/// [request] is the request associated with [response] as reported by the
/// native WebView. Platforms that expose the committed request should report
/// [WebResourceRequestHeaderState.committed].
typedef RawWebResourceResponseCallback =
    void Function(
      RawWebResourceRequest request,
      RawWebResourceResponse response,
    );
