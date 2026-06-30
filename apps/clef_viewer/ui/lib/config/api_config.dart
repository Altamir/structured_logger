/// API base URL for the CLEF Viewer server.
///
/// - `CLEF_VIEWER_API` unset → `http://localhost:5341` (dev)
/// - `CLEF_VIEWER_API=` (empty at build) → same-origin relative paths (Docker/nginx)
/// - `CLEF_VIEWER_VERSION` set at Docker/CI build → shown in UI
class ApiConfig {
  static const String _unset = '__unset__';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'CLEF_VIEWER_API',
      defaultValue: _unset,
    );
    if (fromEnv != _unset) {
      return fromEnv;
    }
    return 'http://localhost:5341';
  }

  /// Git SHA or tag baked in at `flutter build --dart-define`.
  static const String appVersion = String.fromEnvironment(
    'CLEF_VIEWER_VERSION',
    defaultValue: 'dev',
  );

  static const String adminKeyStorageKey = 'clef_viewer_admin_key';
  static const String sessionTokenStorageKey = 'clef_viewer_session_token';

  /// Builds an API URI. Empty [baseUrl] yields a path-only URI (same origin).
  static Uri uri(String path, {Map<String, String>? queryParameters}) {
    if (baseUrl.isEmpty) {
      return Uri(path: path, queryParameters: queryParameters);
    }
    final normalized =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalized$path')
        .replace(queryParameters: queryParameters);
  }

  /// True when API calls use the page origin (production behind nginx).
  static bool get isSameOrigin => baseUrl.isEmpty;

  /// Short label for UI (7-char SHA or full if shorter).
  static String shortLabel(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) return '?';
    if (trimmed.length <= 7) return trimmed;
    return trimmed.substring(0, 7);
  }
}