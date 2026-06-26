/// API base URL for the CLEF Viewer server.
///
/// When [baseUrl] is empty (default in Docker behind nginx proxy), requests use
/// same-origin relative paths. Set `CLEF_VIEWER_API` at build time for split
/// dev setups (e.g. UI on :8080, API on :5341).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'CLEF_VIEWER_API',
    defaultValue: 'http://localhost:5341',
  );

  static const String adminKeyStorageKey = 'clef_viewer_admin_key';

  /// Builds an API URI. Empty [baseUrl] yields a path-only URI (same origin).
  static Uri uri(String path, {Map<String, String>? queryParameters}) {
    if (baseUrl.isEmpty) {
      return Uri(path: path, queryParameters: queryParameters);
    }
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalized$path').replace(queryParameters: queryParameters);
  }
}