import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:structured_logger/structured_logger.dart';

void main() {
  group('SinkSeq', () {
    test('throws ArgumentError when seqUrl is not a valid absolute URL', () {
      expect(
        () => SinkSeq('not-a-url'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sends CLEF body with @t, @mt, @l and data properties', () async {
      late String capturedBody;
      late Uri capturedUri;

      final client = MockClient((request) async {
        capturedBody = request.body;
        capturedUri = request.url;
        return Response('', 201);
      });

      final sink = SinkSeq('http://localhost:5341', client: client);
      await sink.write(LogModel(
        mt: 'Hello {name}',
        level: 'info',
        t: '2024-01-01T00:00:00.000Z',
        data: {'name': 'John'},
      ));

      final body = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(body['@t'], '2024-01-01T00:00:00.000Z');
      expect(body['@mt'], 'Hello {name}');
      expect(body['@l'], 'info');
      expect(body['name'], 'John');
      expect(capturedUri.path, '/api/events/raw');
      expect(capturedUri.query, 'clef');
    });

    test('reserved CLEF fields are not overwritten by event.data', () async {
      late String capturedBody;

      final client = MockClient((request) async {
        capturedBody = request.body;
        return Response('', 201);
      });

      final sink = SinkSeq('https://seq.example.com', client: client);
      await sink.write(LogModel(
        mt: 'Hello {name}',
        level: 'info',
        t: '2024-01-01T00:00:00.000Z',
        data: {
          '@t': 'bad-timestamp',
          '@mt': 'bad-template',
          '@l': 'bad-level',
          'DeviceIdentifier': 'bad-device',
        },
      ));

      final body = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(body['@t'], '2024-01-01T00:00:00.000Z');
      expect(body['@mt'], 'Hello {name}');
      expect(body['@l'], 'info');
      expect(body['DeviceIdentifier'], '');
    });

    test('normalizes seqUrl with trailing slash', () async {
      late Uri capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return Response('', 201);
      });

      final sink = SinkSeq('https://seq.example.com/', client: client);
      await sink.write(LogModel(mt: 'test message'));

      expect(capturedUri.path, '/api/events/raw');
      expect(capturedUri.query, 'clef');
    });

    test('includes DeviceIdentifier in CLEF body', () async {
      late String capturedBody;

      final client = MockClient((request) async {
        capturedBody = request.body;
        return Response('', 201);
      });

      final sink = SinkSeq(
        'https://seq.example.com',
        deviceIdentifier: 'my-device',
        client: client,
      );
      await sink.write(LogModel(mt: 'test message'));

      final body = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(body['DeviceIdentifier'], 'my-device');
    });

    test('sends X-Seq-ApiKey header when apiKey is provided', () async {
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return Response('', 201);
      });

      final sink = SinkSeq(
        'https://seq.example.com',
        apiKey: 'test-api-key',
        client: client,
      );
      await sink.write(LogModel(mt: 'test message'));

      expect(capturedHeaders['X-Seq-ApiKey'], 'test-api-key');
      expect(capturedHeaders['Content-Type'], 'application/vnd.serilog.clef');
    });

    test('follows http to https redirect and retries POST', () async {
      var callCount = 0;
      late Uri redirectedUri;

      final client = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return Response(
            'Permanent Redirect',
            301,
            headers: {
              'location': 'https://seq.example.com/api/events/raw?clef',
            },
          );
        }

        redirectedUri = request.url;
        return Response('', 201);
      });

      final sink = SinkSeq('http://seq.example.com', client: client);
      await sink.write(LogModel(mt: 'test message'));

      expect(callCount, 2);
      expect(redirectedUri.scheme, 'https');
      expect(redirectedUri.path, '/api/events/raw');
      expect(redirectedUri.query, 'clef');
    });

    test('completes without exception on 201 response', () async {
      final client = MockClient((request) async => Response('', 201));
      final sink = SinkSeq('https://seq.example.com', client: client);

      await expectLater(
        sink.write(LogModel(mt: 'test message')),
        completes,
      );
    });

    test('completes without exception on 500 response', () async {
      final client = MockClient((request) async => Response('error', 500));
      final sink = SinkSeq('https://seq.example.com', client: client);

      await expectLater(
        sink.write(LogModel(mt: 'test message')),
        completes,
      );
    });

    test('close disposes owned client without throwing', () {
      final sink = SinkSeq('https://seq.example.com');
      expect(() => sink.close(), returnsNormally);
    });

    test('close does not dispose injected client', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return Response('', 201);
      });

      final sink = SinkSeq('https://seq.example.com', client: client);
      sink.close();

      await sink.write(LogModel(mt: 'test message'));
      expect(requestCount, 1);
    });
  });
}