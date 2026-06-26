import 'dart:async';
import 'dart:convert';

import 'package:clef_viewer_server/api/sse_handler.dart';
import 'package:clef_viewer_server/models/log_entry.dart';
import 'package:clef_viewer_server/stream/event_broadcaster.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('publishes ingested log events on SSE stream within 2 seconds', () async {
    final broadcaster = EventBroadcaster();
    final handler = SseHandler(broadcaster: broadcaster);

    final response = await handler.handle(
      Request('GET', Uri.parse('http://localhost/api/events/stream')),
    );

    expect(response.statusCode, 200);
    expect(response.headers['content-type'], contains('text/event-stream'));

    final completer = Completer<void>();
    var buffer = '';
    final sub = response.read().transform(utf8.decoder).listen((chunk) {
      buffer += chunk;
      if (buffer.contains('data:') && buffer.contains('sse-unit-test')) {
        completer.complete();
      }
    });

    broadcaster.publish(
      const LogEntry(
        id: 1,
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        messageTemplate: 'sse-unit-test',
      ),
    );

    await completer.future.timeout(const Duration(seconds: 2));
    await sub.cancel();
    broadcaster.dispose();
  });
}