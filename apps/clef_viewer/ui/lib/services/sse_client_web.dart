import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/log_entry.dart';

/// Browser SSE client — uses [html.EventSource] (required for Flutter Web).
class SseClient {
  final String baseUrl;
  html.EventSource? _source;
  StreamSubscription<html.MessageEvent>? _messageSub;
  StreamSubscription<html.Event>? _openSub;
  StreamSubscription<html.Event>? _errorSub;
  final _controller = StreamController<LogEntry>.broadcast();
  bool _disposed = false;
  bool _paused = false;
  bool _hadOpen = false;

  /// Called after a successful reconnect (not the initial connection).
  VoidCallback? onReconnect;

  SseClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Stream<LogEntry> get stream => _controller.stream;

  bool get isConnected => _source != null && !_paused;

  void connect() {
    if (_disposed || _paused) return;
    _openSource();
  }

  void disconnect() {
    _paused = true;
    _closeSource();
  }

  void resume() {
    _paused = false;
    _hadOpen = false;
    connect();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }

  void _openSource() {
    _closeSource();

    final url = _streamUrl();
    if (kDebugMode) {
      debugPrint('SSE connecting: $url');
    }

    final source = html.EventSource(url);
    _source = source;

    // Default SSE messages (no custom event type) — best browser support.
    _messageSub = source.onMessage.listen(_onMessage);

    _openSub = source.onOpen.listen((_) {
      if (_disposed || _paused) return;
      if (kDebugMode) {
        debugPrint('SSE open');
      }
      if (_hadOpen) {
        onReconnect?.call();
      }
      _hadOpen = true;
    });

    _errorSub = source.onError.listen((_) {
      if (kDebugMode) {
        debugPrint('SSE error (browser will retry)');
      }
    });
  }

  void _onMessage(html.MessageEvent event) {
    if (_disposed || _paused) return;
    final data = event.data;
    if (data == null || data.toString().isEmpty) return;

    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      if (!json.containsKey('timestamp') || !json.containsKey('level')) {
        return;
      }
      _controller.add(LogEntry.fromJson(json));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SSE parse error: $e');
      }
    }
  }

  void _closeSource() {
    _messageSub?.cancel();
    _messageSub = null;
    _openSub?.cancel();
    _openSub = null;
    _errorSub?.cancel();
    _errorSub = null;

    _source?.close();
    _source = null;
  }

  String _streamUrl() {
    final path = ApiConfig.uri('/api/events/stream');
    if (ApiConfig.isSameOrigin) {
      return '${html.window.location.origin}${path.path}';
    }
    return path.toString();
  }
}