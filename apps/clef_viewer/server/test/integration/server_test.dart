import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clef_viewer_server/api/router.dart';
import 'package:shelf/shelf.dart';
import 'package:clef_viewer_server/config.dart';
import 'package:clef_viewer_server/db/database.dart';
import 'package:clef_viewer_server/db/log_repository.dart';
import 'package:clef_viewer_server/models/filter_constants.dart';
import 'package:clef_viewer_server/models/log_filter.dart';
import 'package:clef_viewer_server/stream/event_broadcaster.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:structured_logger/structured_logger.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late int port;
  late LogRepository repository;
  late EventBroadcaster broadcaster;

  Future<void> startServer(AppConfig config) async {
    final db = openMemoryDatabase();
    repository = LogRepository(db, maxRows: config.maxRows);
    await repository.ensureSchema();
    broadcaster = EventBroadcaster();

    final handler = createHandler(
      config: config,
      repository: repository,
      broadcaster: broadcaster,
    );

    server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    port = server.port;
  }

  setUpAll(() async {
    await startServer(
      const AppConfig(
        port: 0,
        dbPath: ':memory:',
        ingestApiKey: 'ingest-key',
        adminApiKey: 'admin-key',
        maxRows: 100000,
        staticPath: '/nonexistent',
        maxEventBytes: 1048576,
        maxBatchEvents: 1000,
        maxBatchBytes: 10485760,
      ),
    );
  });

  setUp(() async {
    await repository.delete(const LogFilter());
  });

  tearDownAll(() async {
    await server.close(force: true);
    repository.close();
    broadcaster.dispose();
  });

  Uri uri(String path, [Map<String, String>? query]) {
    return Uri(
      scheme: 'http',
      host: 'localhost',
      port: port,
      path: path,
      queryParameters: query,
    );
  }

  group('SinkSeq compatibility', () {
    test('accepts POST /api/events/raw?clef with CLEF body', () async {
      final body = jsonEncode({
        '@t': '2024-01-01T00:00:00.000Z',
        '@mt': 'Hello {name}',
        '@l': 'info',
        'name': 'John',
        'DeviceIdentifier': '',
      });

      final response = await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: body,
      );

      expect(response.statusCode, 201);
      expect(response.body, isEmpty);

      final query = await http.get(uri('/api/events'));
      final data = jsonDecode(query.body) as Map<String, dynamic>;
      final events = data['events'] as List<dynamic>;
      expect(events, hasLength(1));
      final event = events.first as Map<String, dynamic>;
      expect(event['messageTemplate'], 'Hello {name}');
      expect(event['level'], 'info');
      expect(event['properties']['name'], 'John');
    });

    test('reserved fields prevail like SinkSeq spread order', () async {
      // Body matches what SinkSeq emits when event.data contained conflicting
      // reserved keys — spread order in _createClefEvent lets reserved win.
      final body = jsonEncode({
        '@t': '2024-01-01T00:00:00.000Z',
        '@mt': 'Hello {name}',
        '@l': 'info',
        'DeviceIdentifier': '',
      });

      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: body,
      );

      final query = await http.get(uri('/api/events'));
      final event = (jsonDecode(query.body) as Map<String, dynamic>)['events']
          .first as Map<String, dynamic>;
      expect(event['timestamp'], '2024-01-01T00:00:00.000Z');
      expect(event['messageTemplate'], 'Hello {name}');
      expect(event['level'], 'info');
      expect(event['deviceId'], '');
    });

    test('ingest returns 401 without API key when configured', () async {
      final response = await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {'Content-Type': CONTENT_TYPE_CLEF},
        body: jsonEncode({'@mt': 'test'}),
      );
      expect(response.statusCode, 401);
    });

    test('ingest returns 401 with wrong API key', () async {
      final response = await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'wrong-key',
        },
        body: jsonEncode({'@mt': 'test'}),
      );
      expect(response.statusCode, 401);
    });
  });

  group('ingest validation', () {
    test('malformed JSON returns 400 and does not persist', () async {
      final response = await http.post(
        uri('/ingest/clef'),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: 'not-json',
      );
      expect(response.statusCode, 400);
      expect(await repository.count(), 0);
    });

    test('pretty-printed single JSON with CLEF content-type is accepted',
        () async {
      const body = '''
{
  "@mt": "pretty",
  "@l": "info",
  "@t": "2024-01-01T00:00:00Z"
}
''';

      final response = await http.post(
        uri('/ingest/clef'),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: body,
      );
      expect(response.statusCode, 201);
      expect(await repository.count(), 1);
    });

    test('NDJSON batch is atomic on invalid second line', () async {
      const body = '''
{"@mt":"one","@l":"info","@t":"2024-01-02T00:00:00Z"}
not-json
''';

      final response = await http.post(
        uri('/ingest/clef'),
        headers: {
          'Content-Type': 'application/x-ndjson',
          SEQ_API_KEY: 'ingest-key',
        },
        body: body,
      );
      expect(response.statusCode, 400);
      expect(await repository.count(), 0);
    });
  });

  group('ingest and admin', () {
    test('ingest NDJSON batch returns ingested count', () async {
      const body = '''
{"@mt":"one","@l":"info","@t":"2024-01-02T00:00:00Z"}
{"@mt":"two","@l":"error","@t":"2024-01-02T00:00:01Z"}
''';

      final response = await http.post(
        uri('/ingest/clef'),
        headers: {
          'Content-Type': 'application/x-ndjson',
          SEQ_API_KEY: 'ingest-key',
        },
        body: body,
      );

      expect(response.statusCode, 201);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data['ingested'], 2);
    });

    test('admin requires API key', () async {
      final unauthorized = await http.delete(uri('/api/admin/logs'));
      expect(unauthorized.statusCode, 401);

      final authorized = await http.delete(
        uri('/api/admin/logs'),
        headers: {SEQ_API_KEY: 'admin-key'},
      );
      expect(authorized.statusCode, 200);
    });

    test('admin stats returns storage and ingest metrics', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      for (var i = 0; i < 3; i++) {
        await http.post(
          uri('/api/events/raw', {'clef': ''}),
          headers: {
            'Content-Type': CONTENT_TYPE_CLEF,
            SEQ_API_KEY: 'ingest-key',
          },
          body: jsonEncode({
            '@t': now,
            '@mt': 'stats test $i',
            '@l': 'info',
          }),
        );
      }

      final unauthorized = await http.get(uri('/api/admin/stats'));
      expect(unauthorized.statusCode, 401);

      final response = await http.get(
        uri('/api/admin/stats'),
        headers: {SEQ_API_KEY: 'admin-key'},
      );
      expect(response.statusCode, 200);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data['event_count'], 3);
      expect(data['logs_per_second_last_minute'], greaterThan(0));
      expect(data['total_by_period'], isA<List<dynamic>>());
      expect(data['ingest_peaks'], isA<List<dynamic>>());
    });

    test('export returns NDJSON CLEF lines', () async {
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode({
          '@t': '2024-03-01T00:00:00Z',
          '@mt': 'export me',
          '@l': 'warning',
        }),
      );

      final response = await http.get(
        uri('/api/admin/export'),
        headers: {SEQ_API_KEY: 'admin-key'},
      );

      expect(response.statusCode, 200);
      expect(
          response.headers['content-type'], contains('application/x-ndjson'));

      final lines =
          response.body.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines, isNotEmpty);
      final clef = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(clef['@mt'], 'export me');
      expect(clef['@l'], 'warning');
    });

    test('group by level returns counts', () async {
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode(
            {'@mt': 'a', '@l': 'error', '@t': '2024-01-01T00:00:00Z'}),
      );
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode(
            {'@mt': 'b', '@l': 'info', '@t': '2024-01-01T00:00:01Z'}),
      );

      final response = await http.get(
        uri('/api/events/group', {'group_by': 'level'}),
      );
      expect(response.statusCode, 200);
      final groups = (jsonDecode(response.body)
          as Map<String, dynamic>)['groups'] as List<dynamic>;
      expect(groups, isNotEmpty);
    });

    test('rejects malicious property key in group API', () async {
      final response = await http.get(
        uri('/api/events/group', {
          'group_by': 'property',
          'group_property': "x') OR 1=1 --",
        }),
      );
      expect(response.statusCode, 400);
    });

    test('groups by group_property while filtering on property param',
        () async {
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode({
          '@mt': 'screen a',
          '@l': 'info',
          '@t': '2024-01-01T00:00:00Z',
          'Screen': 'Home',
          'UserId': '42',
        }),
      );
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode({
          '@mt': 'screen b',
          '@l': 'info',
          '@t': '2024-01-01T00:00:01Z',
          'Screen': 'Settings',
          'UserId': '42',
        }),
      );

      final response = await http.get(
        uri('/api/events/group', {
          'group_by': 'property',
          'group_property': 'Screen',
          'property': 'UserId=42',
        }),
      );
      expect(response.statusCode, 200);
      final groups = (jsonDecode(response.body)
          as Map<String, dynamic>)['groups'] as List<dynamic>;
      expect(groups, hasLength(2));
    });

    test('filters empty device via sentinel', () async {
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode({
          '@mt': 'no device',
          '@l': 'info',
          '@t': '2024-01-01T00:00:00Z',
          'DeviceIdentifier': '',
        }),
      );
      await http.post(
        uri('/api/events/raw', {'clef': ''}),
        headers: {
          'Content-Type': CONTENT_TYPE_CLEF,
          SEQ_API_KEY: 'ingest-key',
        },
        body: jsonEncode({
          '@mt': 'with device',
          '@l': 'info',
          '@t': '2024-01-01T00:00:01Z',
          'DeviceIdentifier': 'dev-1',
        }),
      );

      final response = await http.get(
        uri('/api/events', {'device_id': FilterConstants.emptySentinel}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data['total'], 1);
    });
  });

  group('SSE', () {
    test('stream endpoint returns text/event-stream', () async {
      final client = HttpClient();
      final request = await client.getUrl(uri('/api/events/stream'));
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.contentType?.mimeType, 'text/event-stream');
      client.close(force: true);
    });

    test('stream delivers connected comment over real TCP', () async {
      final client = HttpClient();
      final request = await client.getUrl(uri('/api/events/stream'));
      final response = await request.close();
      expect(response.statusCode, 200);

      final completer = Completer<void>();
      final sub = response.transform(utf8.decoder).listen((chunk) {
        if (chunk.contains('connected') && !completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();
      client.close(force: true);
    });

    test('POST ingest delivers event on SSE stream through router stack',
        () async {
      final db = openMemoryDatabase();
      final repo = LogRepository(db, maxRows: 100000);
      await repo.ensureSchema();
      final bc = EventBroadcaster();
      final handler = createHandler(
        config: const AppConfig(
          port: 0,
          dbPath: ':memory:',
          ingestApiKey: 'ingest-key',
          adminApiKey: 'admin-key',
          maxRows: 100000,
          staticPath: '/nonexistent',
          maxEventBytes: 1048576,
          maxBatchEvents: 1000,
          maxBatchBytes: 10485760,
        ),
        repository: repo,
        broadcaster: bc,
      );

      final completer = Completer<void>();
      var buffer = '';

      final sseResponse = await handler(
        Request('GET', Uri.parse('http://localhost/api/events/stream')),
      );
      expect(sseResponse.statusCode, 200);
      expect(
          sseResponse.headers['content-type'], contains('text/event-stream'));

      final sub = sseResponse.read().transform(utf8.decoder).listen((chunk) {
        buffer += chunk;
        if (buffer.contains('data:') && buffer.contains('http-sse-ingest')) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final ingestResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/events/raw?clef'),
          headers: {
            'Content-Type': CONTENT_TYPE_CLEF,
            SEQ_API_KEY: 'ingest-key',
          },
          body: jsonEncode({
            '@mt': 'http-sse-ingest',
            '@l': 'info',
            '@t': '2024-01-01T00:00:00Z',
          }),
        ),
      );
      expect(ingestResponse.statusCode, 201);

      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();
      bc.dispose();
      repo.close();
    });
  });

  group('query limit', () {
    test('accepts limit up to queryMaxLimit', () async {
      final response = await http.get(
        uri('/api/events', {'limit': '5000'}),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['limit'], 5000);
    });
  });

  group('CORS', () {
    test('OPTIONS preflight returns CORS headers', () async {
      final client = HttpClient();
      final request = await client.openUrl(
        'OPTIONS',
        uri('/api/events'),
      );
      request.headers.set('Origin', 'http://localhost:8080');
      request.headers.set('Access-Control-Request-Method', 'GET');
      final response = await request.close();
      expect(response.statusCode, 204);
      expect(
        response.headers.value('access-control-allow-origin'),
        'http://localhost:8080',
      );
      client.close();
    });
  });

  group('payload limits', () {
    late HttpServer limitServer;
    late int limitPort;
    late LogRepository limitRepo;

    setUpAll(() async {
      final db = openMemoryDatabase();
      limitRepo = LogRepository(db, maxRows: 100000);
      await limitRepo.ensureSchema();
      final handler = createHandler(
        config: const AppConfig(
          port: 0,
          dbPath: ':memory:',
          ingestApiKey: null,
          adminApiKey: 'admin-key',
          maxRows: 100000,
          staticPath: '/nonexistent',
          maxEventBytes: 50,
          maxBatchEvents: 2,
          maxBatchBytes: 200,
        ),
        repository: limitRepo,
        broadcaster: EventBroadcaster(),
      );
      limitServer =
          await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      limitPort = limitServer.port;
    });

    tearDownAll(() async {
      await limitServer.close(force: true);
      limitRepo.close();
    });

    Uri limitUri(String path) => Uri(
          scheme: 'http',
          host: 'localhost',
          port: limitPort,
          path: path,
          queryParameters: {'clef': ''},
        );

    test('returns 413 for oversized single event', () async {
      final response = await http.post(
        limitUri('/api/events/raw'),
        headers: {'Content-Type': CONTENT_TYPE_CLEF},
        body: jsonEncode({'@mt': 'x' * 100}),
      );
      expect(response.statusCode, 413);
    });

    Uri limitIngestUri() => Uri(
          scheme: 'http',
          host: 'localhost',
          port: limitPort,
          path: '/ingest/clef',
        );

    test('returns 413 when NDJSON batch exceeds max events', () async {
      const body = '''
{"@mt":"one","@l":"info","@t":"2024-01-01T00:00:00Z"}
{"@mt":"two","@l":"info","@t":"2024-01-01T00:00:01Z"}
{"@mt":"three","@l":"info","@t":"2024-01-01T00:00:02Z"}
''';

      final response = await http.post(
        limitIngestUri(),
        headers: {'Content-Type': 'application/x-ndjson'},
        body: body,
      );
      expect(response.statusCode, 413);
    });

    test('returns 413 when NDJSON batch exceeds max bytes', () async {
      final response = await http.post(
        limitIngestUri(),
        headers: {'Content-Type': 'application/x-ndjson'},
        body: '{"@mt":"${'x' * 250}","@l":"info","@t":"2024-01-01T00:00:00Z"}',
      );
      expect(response.statusCode, 413);
    });
  });
}
