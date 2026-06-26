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

    void sendEvent(String event, Object data) {
      final payload = 'event: $event\ndata: ${jsonEncode(data)}\n\n';
      controller.add(utf8.encode(payload));
    }

    sendEvent('heartbeat', {});

    logSub = broadcaster.stream.listen((entry) {
      sendEvent('log', entry.toJson());
    });

    heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      sendEvent('heartbeat', {});
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
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  }
}