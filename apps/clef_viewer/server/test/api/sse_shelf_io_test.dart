import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clef_viewer_server/api/sse_handler.dart';
import 'package:clef_viewer_server/stream/event_broadcaster.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

/// Real TCP test — in-process [response.read()] passes but shelf_io needs
/// [shelf.io.buffer_output] = false on the response.
void main() {
  test('SSE delivers initial bytes over shelf_io within 2 seconds', () async {
    final broadcaster = EventBroadcaster();
    final handler = SseHandler(broadcaster: broadcaster);

    final server = await shelf_io.serve(
      (Request request) => handler.handle(request),
      InternetAddress.loopbackIPv4,
      0,
    );

    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/api/events/stream'),
      );
      final response = await request.close();

      expect(response.statusCode, 200);
      expect(response.headers.contentType?.mimeType, 'text/event-stream');

      final completer = Completer<void>();
      var buffer = '';
      final sub = response.transform(utf8.decoder).listen((chunk) {
        buffer += chunk;
        if (buffer.contains('connected')) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();
      client.close(force: true);
    } finally {
      await server.close(force: true);
      broadcaster.dispose();
    }
  });
}
