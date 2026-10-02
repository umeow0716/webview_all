/// Linux host compatibility information relevant to WebKitGTK startup.
class LinuxHostCompatibility {
  /// Creates Linux host compatibility information.
  const LinuxHostCompatibility({
    required this.webKitGtkMajor,
    required this.webKitGtkMinor,
    required this.webKitGtkMicro,
    required this.nvidiaProprietaryDriverDetected,
    required this.legacyDisableDmabufRendererRequested,
    required this.requiresEarlyRendererWorkaround,
    required this.earlyRendererWorkaroundActive,
  });

  factory LinuxHostCompatibility.fromMap(Map<Object?, Object?> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    bool readBool(String key) => map[key] as bool? ?? false;

    return LinuxHostCompatibility(
      webKitGtkMajor: readInt('webKitGtkMajor'),
      webKitGtkMinor: readInt('webKitGtkMinor'),
      webKitGtkMicro: readInt('webKitGtkMicro'),
      nvidiaProprietaryDriverDetected: readBool(
        'nvidiaProprietaryDriverDetected',
      ),
      legacyDisableDmabufRendererRequested: readBool(
        'legacyDisableDmabufRendererRequested',
      ),
      requiresEarlyRendererWorkaround: readBool(
        'requiresEarlyRendererWorkaround',
      ),
      earlyRendererWorkaroundActive: readBool(
        'earlyRendererWorkaroundActive',
      ),
    );
  }

  /// WebKitGTK runtime major version.
  final int webKitGtkMajor;

  /// WebKitGTK runtime minor version.
  final int webKitGtkMinor;

  /// WebKitGTK runtime micro version.
  final int webKitGtkMicro;

  /// Whether the proprietary NVIDIA kernel driver is detected.
  final bool nvidiaProprietaryDriverDetected;

  /// Whether the legacy `WEBKIT_DISABLE_DMABUF_RENDERER` flag is present.
  final bool legacyDisableDmabufRendererRequested;

  /// Whether this host requires the early renderer workaround.
  final bool requiresEarlyRendererWorkaround;

  /// Whether the renderer environment required by the workaround is active.
  final bool earlyRendererWorkaroundActive;

  /// Whether the host still needs to apply the workaround during startup.
  bool get hostInitializationRequired =>
      requiresEarlyRendererWorkaround && !earlyRendererWorkaroundActive;

  /// Human-readable WebKitGTK runtime version.
  String get webKitGtkVersion =>
      '$webKitGtkMajor.$webKitGtkMinor.$webKitGtkMicro';
}
