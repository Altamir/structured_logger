import 'dart:io';

/// Application configuration loaded from environment variables.
class AppConfig {
  final int port;
  final String dbPath;
  final String? ingestApiKey;
  final String? adminApiKey;
  final int maxRows;
  final int queryMaxLimit;
  final String staticPath;
  final int maxEventBytes;
  final int maxBatchEvents;
  final int maxBatchBytes;
  final bool devMode;
  final String version;

  const AppConfig({
    required this.port,
    required this.dbPath,
    this.ingestApiKey,
    this.adminApiKey,
    required this.maxRows,
    this.queryMaxLimit = 100000,
    required this.staticPath,
    required this.maxEventBytes,
    required this.maxBatchEvents,
    required this.maxBatchBytes,
    this.devMode = false,
    this.version = 'dev',
  });

  factory AppConfig.fromEnvironment() {
    final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 5341;
    final dbPath = Platform.environment['DB_PATH'] ?? './clef_viewer.db';
    final ingestApiKey = _emptyToNull(Platform.environment['INGEST_API_KEY']);
    final adminApiKey = _emptyToNull(Platform.environment['ADMIN_API_KEY']);
    final maxRows =
        int.tryParse(Platform.environment['MAX_ROWS'] ?? '') ?? 100000;
    final queryMaxLimit =
        int.tryParse(Platform.environment['QUERY_MAX_LIMIT'] ?? '') ?? 100000;
    final staticPath = Platform.environment['STATIC_PATH'] ?? '../ui/build/web';
    final maxEventBytes =
        int.tryParse(Platform.environment['MAX_EVENT_BYTES'] ?? '') ?? 1048576;
    final maxBatchEvents =
        int.tryParse(Platform.environment['MAX_BATCH_EVENTS'] ?? '') ?? 1000;
    final maxBatchBytes =
        int.tryParse(Platform.environment['MAX_BATCH_BYTES'] ?? '') ??
            (10 * 1048576);
    final devMode = Platform.environment['DEV_MODE'] == 'true';
    final version = Platform.environment['CLEF_VIEWER_VERSION'] ?? 'dev';

    if (adminApiKey == null && !devMode) {
      stderr.writeln(
        'ERROR: ADMIN_API_KEY must be set. '
        'Set DEV_MODE=true for unprotected local development only.',
      );
      exit(1);
    }

    if (adminApiKey == null && devMode) {
      stderr.writeln(
        'WARNING: ADMIN_API_KEY is not set — admin endpoints are unprotected '
        '(DEV_MODE=true).',
      );
    }

    return AppConfig(
      port: port,
      dbPath: dbPath,
      ingestApiKey: ingestApiKey,
      adminApiKey: adminApiKey,
      maxRows: maxRows,
      queryMaxLimit: queryMaxLimit,
      staticPath: staticPath,
      maxEventBytes: maxEventBytes,
      maxBatchEvents: maxBatchEvents,
      maxBatchBytes: maxBatchBytes,
      devMode: devMode,
      version: version,
    );
  }

  static String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get maxEventBytesLabel {
    if (maxEventBytes >= 1048576) {
      return '${maxEventBytes ~/ 1048576} MB';
    }
    if (maxEventBytes >= 1024) {
      return '${maxEventBytes ~/ 1024} KB';
    }
    return '$maxEventBytes bytes';
  }
}
