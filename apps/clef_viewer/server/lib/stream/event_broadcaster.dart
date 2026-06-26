import 'dart:async';

import '../models/log_entry.dart';

/// Fan-out broadcaster for newly ingested log events (SSE subscribers).
class EventBroadcaster {
  final _controller = StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get stream => _controller.stream;

  void publish(LogEntry entry) {
    if (!_controller.isClosed) {
      _controller.add(entry);
    }
  }

  void dispose() {
    _controller.close();
  }
}
