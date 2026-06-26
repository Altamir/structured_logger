import 'dart:async';

import 'package:dio/dio.dart';
import 'package:structured_logger/structured_logger.dart';
import 'package:uuid/uuid.dart';

const String _templateRequest =
    'REQUEST: {@method} {@path} {@correlationalSeqID} {@data} {@queryParams} {@headers}';
const String _templateResponse =
    'RESPONSE: {@statusCode} {@path} {@correlationalSeqID} {@data} {@headers} {@elapsedTime}';
const String _templateError =
    'ERROR: {@statusCode} {@path} {@correlationalSeqID} {@message} {@errorData} {@headers} {@elapsedTime}';

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

/// Dio interceptor that emits Log Events (REQUEST, RESPONSE, ON_ERROR)
/// via an injected [StructureLogger]. Transport (e.g. to Seq) is delegated
/// to sinks already registered on the logger. Matches legacy semantics
/// for templates, headers, elapsed time, but does not perform direct HTTP.
class DioLoggingInterceptor extends Interceptor {
  DioLoggingInterceptor(
    this._logger, {
    this.correlationalHeaderName = 'X-Request-Seq-Id',
  }) {
    // Always-on check (not assert) to match design ctor contract even in release
    // (dart compile exe etc). Hardening for release safety / to preserve contract;
    // design intent (non-empty header) preserved.
    if (correlationalHeaderName.isEmpty) {
      throw ArgumentError('correlationalHeaderName cannot be empty');
    }
  }

  final StructureLogger _logger;
  final String correlationalHeaderName;
  static const _startTimeHeader = 'X-Request-Start-Time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = const Uuid().v4();
    options.headers[correlationalHeaderName] = id;
    options.headers[_startTimeHeader] = DateTime.now().millisecondsSinceEpoch;

    unawaited(_logger.log(
      _templateRequest,
      level: LogLevel.info,
      data: {
        'event_type': 'REQUEST',
        'method': options.method,
        'path': options.path,
        'correlationalSeqID': id,
        'data': _sanitize(options.data),
        'queryParams': _sanitize(options.queryParameters),
        'headers': _sanitize(options.headers),
      },
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
      data: {
        'event_type': 'RESPONSE',
        'statusCode': response.statusCode,
        'path': response.requestOptions.path,
        'correlationalSeqID': id,
        'data': _sanitize(response.data),
        'headers': _sanitize(
            response.headers.map.map((k, v) => MapEntry(k, v.join(', ')))),
        'elapsedTime': elapsed,
      },
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
      data: {
        'event_type': 'ON_ERROR',
        'statusCode': err.response?.statusCode,
        'path': err.requestOptions.path,
        'correlationalSeqID': id,
        'message': err.message,
        'errorData': _sanitize(err.response?.data),
        'headers': _sanitize(err.requestOptions.headers),
        'elapsedTime': elapsed,
      },
    ));
    super.onError(err, handler);
  }
}
