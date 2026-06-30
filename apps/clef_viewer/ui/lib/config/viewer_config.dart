/// Viewer UI limits and live time windows (compile-time overrides).
class ViewerConfig {
  static int _parseInt(String raw, int fallback) {
    final v = int.tryParse(raw.trim());
    if (v == null || v < 1) return fallback;
    return v;
  }

  static const String _maxEventsRaw = String.fromEnvironment(
    'CLEF_VIEWER_MAX_EVENTS',
    defaultValue: '100000',
  );

  static const String _liveBootSecRaw = String.fromEnvironment(
    'CLEF_VIEWER_LIVE_BOOT_SEC',
    defaultValue: '60',
  );

  static const String _liveSteadySecRaw = String.fromEnvironment(
    'CLEF_VIEWER_LIVE_STEADY_SEC',
    defaultValue: '180',
  );

  static int get maxDisplayedEvents => _parseInt(_maxEventsRaw, 100000);

  static Duration get liveWindowBoot =>
      Duration(seconds: _parseInt(_liveBootSecRaw, 60));

  static Duration get liveWindowSteady =>
      Duration(seconds: _parseInt(_liveSteadySecRaw, 180));
}