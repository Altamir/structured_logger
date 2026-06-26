import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/log_entry.dart';

/// SSE client with exponential backoff reconnect (1s → 30s cap).
class SseClient {
  final String baseUrl;
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  final _controller = StreamController<LogEntry>.broadcast();
  bool _disposed = false;
  bool _paused = false;
  int _attempt = 0;

  /// Called after a successful reconnect (not the initial connection).
  VoidCallback? onReconnect;

  SseClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Stream<LogEntry> get stream => _controller.stream;

  bool get isConnected => _subscription != null && !_paused;

  void connect() {
    if (_disposed || _paused) return;
    _connectInternal();
  }

  void disconnect() {
    _paused = true;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }

  void resume() {
    _paused = false;
    _attempt = 0;
    connect();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }

  Future<void> _connectInternal() async {
    _subscription?.cancel();
    _client?.close();
    _client = http.Client();

    final uri = ApiConfig.uri('/api/events/stream');
    final request = http.Request('GET', uri);
    request.headers['Accept'] = 'text/event-stream';

    try {
      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        _scheduleReconnect();
        return;
      }

      final isReconnect = _attempt > 0;
      _attempt = 0;
      if (isReconnect) {
        onReconnect?.call();
      }

      var buffer = '';
      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              buffer += chunk;
              while (buffer.contains('\n\n')) {
                final index = buffer.indexOf('\n\n');
                final block = buffer.substring(0, index);
                buffer = buffer.substring(index + 2);
                _handleBlock(block);
              }
            },
            onError: (_) => _scheduleReconnect(),
            onDone: () => _scheduleReconnect(),
            cancelOnError: true,
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SSE connect error: $e');
      }
      _scheduleReconnect();
    }
  }

  void _handleBlock(String block) {
    String? eventType;
    final dataLines = <String>[];

    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }

    if (eventType == 'log' && dataLines.isNotEmpty) {
      final json = jsonDecode(dataLines.join('\n')) as Map<String, dynamic>;
      _controller.add(LogEntry.fromJson(json));
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _paused) return;
    _subscription?.cancel();
    _subscription = null;

    final delays = [1, 2, 4, 8, 16, 30];
    final delaySeconds = delays[_attempt.clamp(0, delays.length - 1)];
    _attempt++;

    Future<void>.delayed(Duration(seconds: delaySeconds), () {
      if (!_disposed && !_paused) {
        _connectInternal();
      }
    });
  }
}