import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clef_viewer_server/api/sse_handler.dart';
import 'package:clef_viewer_server/models/log_entry.dart';
import 'package:clef_viewer_server/stream/event_broadcaster.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

void main() {
  test('SseHandler delivers initial bytes and events over shelf_io', () async {
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

      final connected = Completer<void>();
      final event = Completer<void>();
      var buffer = '';
      final sub = response.transform(utf8.decoder).listen((chunk) {
        buffer += chunk;
        if (buffer.contains('connected') && !connected.isCompleted) {
          connected.complete();
        }
        if (buffer.contains('shelf-io-test') && !event.isCompleted) {
          event.complete();
        }
      });

      await connected.future.timeout(const Duration(seconds: 2));

      broadcaster.publish(
        const LogEntry(
          id: 1,
          timestamp: '2024-01-01T00:00:00Z',
          level: 'info',
          messageTemplate: 'shelf-io-test',
        ),
      );

      await event.future.timeout(const Duration(seconds: 2));
      await sub.cancel();
      client.close(force: true);
    } finally {
      await server.close(force: true);
      broadcaster.dispose();
    }
  });
}