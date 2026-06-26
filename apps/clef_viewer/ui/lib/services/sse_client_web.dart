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
  StreamSubscription<html.Event>? _openSub;
  html.EventListener? _logListener;
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

    final source = html.EventSource(_streamUrl());
    _source = source;

    _logListener = (html.Event event) {
      if (_disposed || _paused) return;
      final message = event as html.MessageEvent;
      final data = message.data;
      if (data == null || data.toString().isEmpty) return;

      try {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        _controller.add(LogEntry.fromJson(json));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SSE parse error: $e');
        }
      }
    };
    source.addEventListener('log', _logListener!);

    _openSub = source.onOpen.listen((_) {
      if (_disposed || _paused) return;
      if (_hadOpen) {
        onReconnect?.call();
      }
      _hadOpen = true;
    });
  }

  void _closeSource() {
    _openSub?.cancel();
    _openSub = null;

    if (_source != null && _logListener != null) {
      _source!.removeEventListener('log', _logListener);
    }
    _logListener = null;

    _source?.close();
    _source = null;
  }

  String _streamUrl() => ApiConfig.uri('/api/events/stream').toString();
}