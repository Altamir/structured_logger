import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../auth/session_store.dart';
import '../clef/clef_parser.dart';
import '../clef/clef_serializer.dart';
import '../config.dart';
import '../db/log_repository.dart';
import '../stream/event_broadcaster.dart';
import 'admin_handler.dart';
import 'auth_handler.dart';
import 'group_handler.dart';
import 'ingest_handler.dart';
import 'middleware/api_key_middleware.dart';
import 'middleware/cors_middleware.dart';
import 'middleware/session_middleware.dart';
import 'query_handler.dart';
import 'sse_handler.dart';

/// Builds the full shelf handler stack for the CLEF Viewer server.
Handler createHandler({
  required AppConfig config,
  required LogRepository repository,
  required EventBroadcaster broadcaster,
}) {
  final parser = ClefParser(maxEventBytes: config.maxEventBytes);
  final ingest = IngestHandler(
    parser: parser,
    repository: repository,
    broadcaster: broadcaster,
    config: config,
  );
  final query = QueryHandler(
    repository: repository,
    maxQueryLimit: config.queryMaxLimit,
  );
  final group = GroupHandler(repository: repository);
  final admin = AdminHandler(
    repository: repository,
    serializer: ClefSerializer(),
    dbPath: config.dbPath,
  );
  final sse = SseHandler(broadcaster: broadcaster);
  final sessionStore = SessionStore();
  final auth = AuthHandler(config: config, sessionStore: sessionStore);

  final ingestAuth = apiKeyMiddleware(
    expectedKey: config.ingestApiKey,
    required: config.ingestApiKey != null,
  );
  final adminAuth = apiKeyMiddleware(
    expectedKey: config.adminApiKey,
    required: config.adminApiKey != null,
  );
  final sessionAuth = sessionMiddleware(sessionStore: sessionStore);

  final router = Router();

  router.post(
    '/api/events/raw',
    (Request request) => ingestAuth((r) => ingest.handleRaw(r))(request),
  );
  router.post(
    '/ingest/clef',
    (Request request) => ingestAuth((r) => ingest.handleIngestClef(r))(request),
  );
  router.post('/api/auth/login', auth.login);
  router.post('/api/auth/logout', auth.logout);
  router.get(
    '/api/events',
    (Request request) => sessionAuth((r) => query.handle(r))(request),
  );
  router.get(
    '/api/events/group',
    (Request request) => sessionAuth((r) => group.handle(r))(request),
  );
  router.get(
    '/api/events/stream',
    (Request request) => sessionAuth((r) => sse.handle(r))(request),
  );
  router.delete(
    '/api/admin/logs',
    (Request request) => adminAuth((r) => admin.deleteLogs(r))(request),
  );
  router.get(
    '/api/admin/export',
    (Request request) => adminAuth((r) => admin.exportLogs(r))(request),
  );
  router.get(
    '/api/admin/stats',
    (Request request) => adminAuth((r) => admin.getStats(r))(request),
  );
  router.get('/health', (Request request) async {
    final count = await repository.count();
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'events': count,
        'version': config.version,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  Handler apiHandler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router);

  final staticDir = Directory(config.staticPath);
  if (staticDir.existsSync()) {
    final staticHandler = createStaticHandler(
      staticDir.path,
      defaultDocument: 'index.html',
    );
    return (Request request) {
      if (_isApiPath(request.url.path)) {
        return apiHandler(request);
      }
      return staticHandler(request);
    };
  }

  return apiHandler;
}

bool _isApiPath(String path) {
  return path.startsWith('api/') ||
      path == 'health' ||
      path.startsWith('ingest/');
}
