import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:structured_logger/structured_logger.dart';

import '../clef/clef_parser.dart';
import '../config.dart';
import '../db/log_repository.dart';
import '../stream/event_broadcaster.dart';
import 'errors.dart';

class IngestHandler {
  final ClefParser parser;
  final LogRepository repository;
  final EventBroadcaster broadcaster;
  final AppConfig config;

  IngestHandler({
    required this.parser,
    required this.repository,
    required this.broadcaster,
    required this.config,
  });

  Future<Response> handleRaw(Request request) async {
    if (request.method != 'POST') {
      return Response(405);
    }

    if (request.url.queryParameters['clef'] == null) {
      return const ApiError(
        code: 'INVALID_REQUEST',
        message: 'Missing clef query parameter',
        status: 400,
      ).toResponse();
    }

    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.contains(CONTENT_TYPE_CLEF)) {
      return const ApiError(
        code: 'INVALID_CONTENT_TYPE',
        message: 'Content-Type must be $CONTENT_TYPE_CLEF',
        status: 400,
      ).toResponse();
    }

    final body = await request.readAsString();
    return _ingestBody(body, emptyResponse: true);
  }

  Future<Response> handleIngestClef(Request request) async {
    if (request.method != 'POST') {
      return Response(405);
    }

    final contentType = request.headers['content-type'] ?? '';
    final isClef = contentType.contains(CONTENT_TYPE_CLEF);
    final isNdjson = contentType.contains('application/x-ndjson');

    if (!isClef && !isNdjson) {
      return const ApiError(
        code: 'INVALID_CONTENT_TYPE',
        message:
            'Content-Type must be $CONTENT_TYPE_CLEF or application/x-ndjson',
        status: 400,
      ).toResponse();
    }

    final body = await request.readAsString();

    if (isNdjson) {
      return _ingestNdjson(body);
    }

    return _ingestBody(body, emptyResponse: false);
  }

  Future<Response> _ingestBody(String body,
      {required bool emptyResponse}) async {
    try {
      final entry = parser.parseJsonString(body);
      final saved = await repository.insert(entry);
      broadcaster.publish(saved);

      if (emptyResponse) {
        return Response(201);
      }
      return Response(
        201,
        body: jsonEncode({'ingested': 1}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ClefParseException catch (e) {
      return ApiError(
        code: 'INVALID_JSON',
        message: e.message,
        status: 400,
      ).toResponse();
    } on PayloadTooLargeException catch (e) {
      return _payloadTooLarge(e);
    } on BatchLimitExceededException catch (e) {
      return _batchTooLarge(e);
    } on StorageBusyException {
      return const ApiError(
        code: 'STORAGE_BUSY',
        message: 'Storage temporarily unavailable',
        status: 503,
      ).toResponse();
    } on StorageFullException {
      return const ApiError(
        code: 'STORAGE_FULL',
        message: 'Storage full',
        status: 507,
      ).toResponse();
    } catch (e, st) {
      return internalError(e, st);
    }
  }

  Future<Response> _ingestNdjson(String body) async {
    try {
      _checkBatchLimits(body);
      final entries = parser.parseNdjson(body);
      if (entries.isEmpty) {
        return Response(
          201,
          body: jsonEncode({'ingested': 0}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final saved = await repository.insertAll(entries);
      for (final entry in saved) {
        broadcaster.publish(entry);
      }

      return Response(
        201,
        body: jsonEncode({'ingested': saved.length}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ClefParseException catch (e) {
      return ApiError(
        code: 'INVALID_JSON',
        message: e.message,
        status: 400,
      ).toResponse();
    } on PayloadTooLargeException catch (e) {
      return _payloadTooLarge(e);
    } on BatchLimitExceededException catch (e) {
      return _batchTooLarge(e);
    } on StorageBusyException {
      return const ApiError(
        code: 'STORAGE_BUSY',
        message: 'Storage temporarily unavailable',
        status: 503,
      ).toResponse();
    } on StorageFullException {
      return const ApiError(
        code: 'STORAGE_FULL',
        message: 'Storage full',
        status: 507,
      ).toResponse();
    } catch (e, st) {
      return internalError(e, st);
    }
  }

  void _checkBatchLimits(String body) {
    final bytes = utf8.encode(body).length;
    if (bytes > config.maxBatchBytes) {
      throw BatchLimitExceededException(
        'Batch body exceeds ${config.maxBatchBytes} bytes',
        config.maxBatchBytes,
      );
    }
    final lineCount =
        body.split('\n').where((line) => line.trim().isNotEmpty).length;
    if (lineCount > config.maxBatchEvents) {
      throw BatchLimitExceededException(
        'Batch exceeds ${config.maxBatchEvents} events',
        config.maxBatchEvents,
      );
    }
  }

  Response _payloadTooLarge(PayloadTooLargeException e) {
    return ApiError(
      code: 'PAYLOAD_TOO_LARGE',
      message: 'Event exceeds configured limit (${config.maxEventBytesLabel})',
      status: 413,
    ).toResponse();
  }

  Response _batchTooLarge(BatchLimitExceededException e) {
    return ApiError(
      code: 'PAYLOAD_TOO_LARGE',
      message: e.message,
      status: 413,
    ).toResponse();
  }
}
