import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models/log_entry.dart';
import '../stream/event_broadcaster.dart';

class SseHandler {
  final EventBroadcaster broadcaster;

  SseHandler({required this.broadcaster});

  Future<Response> handle(Request request) async {
    final controller = StreamController<List<int>>();
    StreamSubscription<LogEntry>? logSub;
    Timer? heartbeat;

    void sendLog(Object data) {
      // Default SSE message (no custom event type) — works with EventSource.onMessage.
      final payload = 'data: ${jsonEncode(data)}\n\n';
      controller.add(utf8.encode(payload));
    }

    void sendHeartbeat() {
      // SSE comment line — keeps connection alive without client events.
      controller.add(utf8.encode(': heartbeat\n\n'));
    }

    sendHeartbeat();

    logSub = broadcaster.stream.listen((entry) {
      sendLog(entry.toJson());
    });

    heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      sendHeartbeat();
    });

    controller.onCancel = () async {
      await logSub?.cancel();
      heartbeat?.cancel();
      await controller.close();
    };

    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    );
  }
}