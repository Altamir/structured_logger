import 'dart:async';

import 'package:dio/dio.dart';
import 'package:structured_logger/structured_logger.dart';
import 'package:uuid/uuid.dart';

const String _templateRequest =
    'REQUEST: {method} {path} {correlationalSeqID} {queryParams} {headers}';
const String _templateResponse =
    'RESPONSE: {statusCode} {path} {correlationalSeqID} {headers} {elapsedTime}';
const String _templateError =
    'ERROR: {statusCode} {path} {correlationalSeqID} {message} {headers} {elapsedTime}';

/// Sanitize values for safe inclusion in LogModel.data (prevents
/// JsonUnsupportedObjectError downstream in sinks like SinkSeq when
/// bodies contain FormData, custom objects, etc.).
/// Hardening for release safety / contract preservation; design intent
/// (log full request/response semantics) preserved for serializable cases.
Object? _sanitize(Object? v) {
  if (v == null || v is String || v is num || v is bool) return v;
  if (v is Map) {
    return v.map((k, vv) => MapEntry(k.toString(), _sanitize(vv)));
  }
  if (v is List) return v.map(_sanitize).toList();
  if (v is Iterable) return v.map(_sanitize).toList();
  return v.toString();
}

Map<String, dynamic> _queryParamsOrEmpty(Map<String, dynamic>? params) {
  final sanitized = _sanitize(params);
  if (sanitized is Map) {
    return Map<String, dynamic>.from(sanitized);
  }
  return {};
}

String _stringOrEmpty(Object? value) => value?.toString() ?? '';

String? _headerValue(Map<dynamic, dynamic> headers, String name) {
  final target = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toString().toLowerCase() == target) {
      final value = entry.value?.toString().trim();
      if (value == null || value.isEmpty) return null;
      return value;
    }
  }
  return null;
}

Map<String, dynamic> _withDeviceIdentifier(
  Map<String, dynamic> data,
  Map<dynamic, dynamic> headers,
  String deviceHeaderName,
) {
  final deviceId = _headerValue(headers, deviceHeaderName);
  if (deviceId == null) return data;
  return {...data, 'DeviceIdentifier': deviceId};
}

/// Dio interceptor that emits Log Events (REQUEST, RESPONSE, ON_ERROR)
/// via an injected [StructureLogger]. Transport (e.g. to Seq) is delegated
/// to sinks already registered on the logger. Message templates use
/// `{property}` placeholders aligned with [StructureLogger]; request/response
/// bodies are emitted as properties only (`data`, `errorData`), not in `@mt`.
class DioLoggingInterceptor extends Interceptor {
  DioLoggingInterceptor(
    this._logger, {
    this.correlationalHeaderName = 'X-Request-Seq-Id',
    this.deviceHeaderName = 'X-device-id',
  }) {
    // Always-on check (not assert) to match design ctor contract even in release
    // (dart compile exe etc). Hardening for release safety / to preserve contract;
    // design intent (non-empty header) preserved.
    if (correlationalHeaderName.isEmpty) {
      throw ArgumentError('correlationalHeaderName cannot be empty');
    }
    if (deviceHeaderName.isEmpty) {
      throw ArgumentError('deviceHeaderName cannot be empty');
    }
  }

  final StructureLogger _logger;
  final String correlationalHeaderName;
  final String deviceHeaderName;
  static const _startTimeHeader = 'X-Request-Start-Time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = const Uuid().v4();
    options.headers[correlationalHeaderName] = id;
    options.headers[_startTimeHeader] = DateTime.now().millisecondsSinceEpoch;

    unawaited(_logger.log(
      _templateRequest,
      level: LogLevel.info,
      data: _withDeviceIdentifier(
        {
          'event_type': 'REQUEST',
          'method': options.method,
          'path': options.path,
          'correlationalSeqID': id,
          'data': _sanitize(options.data),
          'queryParams': _queryParamsOrEmpty(options.queryParameters),
          'headers': _sanitize(options.headers),
        },
        options.headers,
        deviceHeaderName,
      ),
    ));
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.headers[correlationalHeaderName];
    final start =
        response.requestOptions.headers[_startTimeHeader] as int? ?? 0;
    // Clamp for safety (clock skew etc); hardening for release safety while
    // preserving design elapsed calc + template behavior.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = start > 0 ? (nowMs - start).clamp(0, 0x7fffffffffffffff) : 0;

    unawaited(_logger.log(
      _templateResponse,
      level: LogLevel.info,
      data: _withDeviceIdentifier(
        {
          'event_type': 'RESPONSE',
          'statusCode': response.statusCode,
          'path': response.requestOptions.path,
          'correlationalSeqID': id,
          'data': _sanitize(response.data),
          'headers': _sanitize(
              response.headers.map.map((k, v) => MapEntry(k, v.join(', ')))),
          'elapsedTime': elapsed,
        },
        response.requestOptions.headers,
        deviceHeaderName,
      ),
    ));
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.headers[correlationalHeaderName];
    final start = err.requestOptions.headers[_startTimeHeader] as int? ?? 0;
    // Clamp for safety (clock skew etc); hardening for release safety while
    // preserving design elapsed calc + template behavior.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = start > 0 ? (nowMs - start).clamp(0, 0x7fffffffffffffff) : 0;

    unawaited(_logger.log(
      _templateError,
      level: LogLevel.error,
      data: _withDeviceIdentifier(
        {
          'event_type': 'ON_ERROR',
          'statusCode': err.response?.statusCode ?? '',
          'path': err.requestOptions.path,
          'correlationalSeqID': id,
          'message': _stringOrEmpty(err.message),
          'errorData': _sanitize(err.response?.data),
          'headers': _sanitize(err.requestOptions.headers),
          'elapsedTime': elapsed,
        },
        err.requestOptions.headers,
        deviceHeaderName,
      ),
    ));
    super.onError(err, handler);
  }
}
