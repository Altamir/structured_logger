import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../clef/clef_serializer.dart';
import '../db/log_repository.dart';
import '../models/log_filter.dart';
import 'errors.dart';

class AdminHandler {
  final LogRepository repository;
  final ClefSerializer serializer;

  AdminHandler({
    required this.repository,
    required this.serializer,
  });

  Future<Response> deleteLogs(Request request) async {
    if (request.method != 'DELETE') {
      return Response(405);
    }

    try {
      final params = Map<String, String>.from(request.url.queryParameters);
      final filter = LogFilter.fromQueryParams(params);
      filter.validate();

      final deleted = await repository.delete(filter);
      return Response.ok(
        jsonEncode({'deleted': deleted}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ValidationException catch (e) {
      return ApiError(
        code: 'INVALID_FILTER',
        message: e.message,
        status: 400,
      ).toResponse();
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

  Future<Response> exportLogs(Request request) async {
    try {
      final params = Map<String, String>.from(request.url.queryParameters);
      final filter = LogFilter.fromQueryParams(params);
      filter.validate();

      final timestamp = DateTime.now().toUtc();
      final filename =
          'logs-${timestamp.toIso8601String().replaceAll(':', '').split('.').first}Z.clef';

      final stream = repository.export(filter).map((entry) {
        return utf8.encode('${serializer.toNdjsonLine(entry)}\n');
      });

      return Response.ok(
        stream,
        headers: {
          'Content-Type': 'application/x-ndjson',
          'Content-Disposition': 'attachment; filename="$filename"',
        },
      );
    } on ValidationException catch (e) {
      return ApiError(
        code: 'INVALID_FILTER',
        message: e.message,
        status: 400,
      ).toResponse();
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
}