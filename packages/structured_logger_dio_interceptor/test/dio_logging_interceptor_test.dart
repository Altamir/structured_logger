import 'dart:async';

import 'package:dio/dio.dart';
import 'package:structured_logger/structured_logger.dart';
import 'package:structured_logger_dio_interceptor/structured_logger_dio_interceptor.dart';
import 'package:test/test.dart';

/// In-memory LogSink for testing interceptor emissions (no network).
class CaptureSink extends LogSink {
  final events = <LogModel>[];

  @override
  Future<void> write(LogModel event) async => events.add(event);
}

/// Minimal adapter that throws to exercise onError path through Dio (handler managed by Dio).
class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      message: 'Server exploded',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter variant that throws DioException *with* response.statusCode for realistic onError path.
/// (Minimal duplication of _FailingAdapter for test coverage; names kept simple.)
class _FailingAdapterWithStatus implements HttpClientAdapter {
  final int statusCode;
  _FailingAdapterWithStatus(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: statusCode,
      ),
      message: 'unavailable',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DioLoggingInterceptor', () {
    late CaptureSink sink;
    late StructureLogger logger;

    setUp(() {
      sink = CaptureSink();
      logger = StructureLogger()..addSink(sink);
    });

    test(
        'constructor throws ArgumentError when correlationalHeaderName is empty',
        () {
      expect(
        () => DioLoggingInterceptor(logger, correlationalHeaderName: ''),
        throwsA(predicate<ArgumentError>(
            (e) => e.message.toString().contains('cannot be empty'))),
      );
    });

    test(
        'onRequest emits REQUEST event with UUID header, start time, and properties',
        () {
      final interceptor = DioLoggingInterceptor(logger);
      final options = RequestOptions(path: '/api/foo', method: 'GET');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(sink.events, hasLength(1));
      final event = sink.events.first;
      expect(event.mt, startsWith('REQUEST:'));
      expect(event.level, 'info');
      final data = event.data!;
      expect(data['event_type'], 'REQUEST');
      expect(data['method'], 'GET');
      expect(data['path'], '/api/foo');
      expect(data['correlationalSeqID'], isA<String>());
      expect((data['correlationalSeqID'] as String).isNotEmpty, true);
      expect(options.headers['X-Request-Seq-Id'], data['correlationalSeqID']);
      expect(options.headers['X-Request-Start-Time'], isA<int>());
    });

    test('supports custom correlationalHeaderName roundtrip', () {
      final interceptor = DioLoggingInterceptor(logger,
          correlationalHeaderName: 'X-Custom-Seq');
      final options = RequestOptions(path: '/api/custom', method: 'GET');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      final data = sink.events.last.data!;
      expect(data['correlationalSeqID'], isA<String>());
      expect(options.headers['X-Custom-Seq'], data['correlationalSeqID']);
      expect(options.headers.containsKey('X-Request-Seq-Id'), isFalse);
    });

    test('onResponse emits RESPONSE with elapsedTime and mapped headers', () {
      final interceptor = DioLoggingInterceptor(logger);
      final options = RequestOptions(path: '/api/bar', method: 'POST');
      // simulate prior onRequest
      final start = DateTime.now().millisecondsSinceEpoch - 42;
      options.headers['X-Request-Seq-Id'] = 'req-123';
      options.headers['X-Request-Start-Time'] = start;

      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'ok': true},
      );
      // headers in response
      response.headers = Headers.fromMap({
        'content-type': ['application/json'],
      });

      final handler = ResponseInterceptorHandler();

      interceptor.onResponse(response, handler);

      expect(sink.events, hasLength(1));
      final event = sink.events.first;
      expect(event.mt, startsWith('RESPONSE:'));
      expect(event.level, 'info');
      final data = event.data!;
      expect(data['event_type'], 'RESPONSE');
      expect(data['statusCode'], 200);
      expect(data['path'], '/api/bar');
      expect(data['correlationalSeqID'], 'req-123');
      expect(data['elapsedTime'], greaterThanOrEqualTo(0));
      expect(data['headers'], isA<Map>());
      expect((data['headers'] as Map)['content-type'], 'application/json');
    });

    test('elapsedTime clamps to >=0 on missing or negative start header', () {
      final interceptor = DioLoggingInterceptor(logger);
      // missing header case (exercises ?? 0 path)
      final optsMissing = RequestOptions(path: '/api/missing');
      optsMissing.headers['X-Request-Seq-Id'] = 'miss-1';
      // deliberately do NOT set X-Request-Start-Time
      final respMissing = Response(requestOptions: optsMissing, statusCode: 200);
      respMissing.headers = Headers.fromMap({});
      interceptor.onResponse(respMissing, ResponseInterceptorHandler());
      final dataMissing = sink.events.last.data!;
      expect(dataMissing['elapsedTime'], 0);

      // negative case
      final options = RequestOptions(path: '/api/neg');
      options.headers['X-Request-Seq-Id'] = 'neg-1';
      options.headers['X-Request-Start-Time'] =
          DateTime.now().millisecondsSinceEpoch + 999999;
      final response = Response(requestOptions: options, statusCode: 200);
      response.headers = Headers.fromMap({});
      interceptor.onResponse(response, ResponseInterceptorHandler());
      final data = sink.events.last.data!;
      expect(data['elapsedTime'], 0); // clamped
      expect(data['event_type'], 'RESPONSE');
    });

    test('onError emits ON_ERROR with optional statusCode and elapsed',
        () async {
      // NOTE: onError exercised only via Dio adapter (not direct unit call on
      // method) because ErrorInterceptorHandler's completer.completeError
      // produces uncaught errors in isolation; Dio queue manages it. See Issue 27.
      // Use real Dio + failing adapter so Dio manages ErrorInterceptorHandler internally (avoids uncaught completeError in manual calls)
      final interceptor = DioLoggingInterceptor(logger);
      final dio = Dio()
        ..interceptors.add(interceptor)
        ..httpClientAdapter = _FailingAdapter();

      try {
        await dio.get('/api/err',
            options: Options(headers: {
              'X-Request-Seq-Id': 'err-456',
              'X-Request-Start-Time': DateTime.now().millisecondsSinceEpoch - 5,
            }));
      } catch (_) {
        // expected from adapter
      }

      // Note: onError path will have been exercised (onRequest also runs before error).
      // Headers injected above may be augmented by onRequest (correl ID set).
      expect(
          sink.events.any((e) => e.data?['event_type'] == 'ON_ERROR'), isTrue,
          reason:
              'should have logged at least one ON_ERROR via Dio error path');
      final errEvent =
          sink.events.firstWhere((e) => e.data?['event_type'] == 'ON_ERROR');
      expect(errEvent.mt, startsWith('ERROR:'));
      expect(errEvent.level, 'error');
      final data = errEvent.data!;
      expect(data['path'], '/api/err');
      expect(data['message'], 'Server exploded');
      expect(data['event_type'], 'ON_ERROR');
      expect(data['elapsedTime'], greaterThanOrEqualTo(0));
      expect(data['correlationalSeqID'], isNotNull);
      expect(data['headers'], isA<Map>());
    });

    test('ON_ERROR with populated statusCode', () async {
      // Use full Dio + adapter (with response) to avoid fragile direct ErrorInterceptorHandler
      // (which causes uncaught InterceptorState and pollutes later tests, as noted in design intent).
      final interceptor = DioLoggingInterceptor(logger);
      final dio = Dio()
        ..interceptors.add(interceptor)
        ..httpClientAdapter = _FailingAdapterWithStatus(503);

      try {
        await dio.get('/api/err-status', options: Options(headers: {
          'X-Request-Seq-Id': 's-1',
          'X-Request-Start-Time': DateTime.now().millisecondsSinceEpoch - 10,
        }));
      } catch (_) {
        // expected
      }

      // onRequest + onError will have fired
      expect(sink.events.any((e) => e.data?['event_type'] == 'ON_ERROR'), isTrue);
      final errEvent = sink.events.firstWhere((e) => e.data?['event_type'] == 'ON_ERROR');
      final data = errEvent.data!;
      expect(data['statusCode'], 503);
      expect(data['message'], 'unavailable');
      expect(data['path'], '/api/err-status');
      expect(data['elapsedTime'], greaterThanOrEqualTo(0));
    });

    test('does not throw when logger has no sinks', () {
      final emptyLogger = StructureLogger();
      final interceptor = DioLoggingInterceptor(emptyLogger);
      final options = RequestOptions(path: '/noop');
      final handler = RequestInterceptorHandler();

      // should not throw even with no sinks registered
      expect(() => interceptor.onRequest(options, handler), returnsNormally);
    });

    test('fire-and-forget works (log call returns before sink completes)', () async {
      // dedicated capture not shared
      final cap = CaptureSink();
      final l = StructureLogger()..addSink(cap);
      final interceptor = DioLoggingInterceptor(l);
      final options = RequestOptions(path: '/ff');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      // emission scheduled async but test observes side effect eventually
      await Future.delayed(Duration.zero);
      expect(cap.events, hasLength(1));
      expect(cap.events.first.data!['event_type'], 'REQUEST');
    });

    test('sanitizes non-serializable data bodies to prevent JSON errors', () {
      final interceptor = DioLoggingInterceptor(logger);
      final options = RequestOptions(path: '/api/form');
      options.data = _NonSerializable('secret-body'); // e.g. would be FormData
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      final data = sink.events.last.data!;
      expect(data['event_type'], 'REQUEST');
      // should be stringified, not raw object
      expect(data['data'], isA<String>());
      expect(data['data'].toString(), contains('secret-body'));
    });

    test('cross-package: interceptor emits via StructureLogger + CaptureSink (no net)', () {
      // Demonstrates full delegation path (interceptor pkg + core logger/sink)
      final cap = CaptureSink();
      final l = StructureLogger()..addSink(cap);
      final i = DioLoggingInterceptor(l);
      final opts = RequestOptions(path: '/cross', method: 'POST');
      i.onRequest(opts, RequestInterceptorHandler());
      expect(cap.events, hasLength(1));
      expect(cap.events.single.data!['event_type'], 'REQUEST');
      expect(cap.events.single.data!['path'], '/cross');
    });
  });
}

/// Non-primitive to simulate Dio FormData / custom body that would break json.encode.
class _NonSerializable {
  final String value;
  _NonSerializable(this.value);
  @override
  String toString() => 'NonSerializable($value)';
}
