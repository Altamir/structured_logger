import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models/log_entry.dart';
import '../stream/event_broadcaster.dart';

class SseHandler {
  final EventBroadcaster broadcaster;

  SseHandler({required this.broadcaster});

  Response handle(Request request) {
    final controller = StreamController<List<int>>();

    controller.add(utf8.encode(': connected\n\n'));

    final logSub = broadcaster.stream.listen((LogEntry entry) {
      controller.add(utf8.encode('data: ${jsonEncode(entry.toJson())}\n\n'));
    });

    final heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!controller.isClosed) {
        controller.add(utf8.encode(': heartbeat\n\n'));
      }
    });

    controller.onCancel = () {
      heartbeat.cancel();
      logSub.cancel();
    };

    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
      // shelf_io buffers chunked bodies by default — SSE never reaches the client.
      context: {'shelf.io.buffer_output': false},
    );
  }
}