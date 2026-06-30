import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../db/log_repository.dart';
import '../models/log_filter.dart';
import 'errors.dart';

class QueryHandler {
  final LogRepository repository;
  final int maxQueryLimit;

  QueryHandler({
    required this.repository,
    this.maxQueryLimit = 100000,
  });

  Future<Response> handle(Request request) async {
    try {
      final params = Map<String, String>.from(request.url.queryParameters);
      final filter = LogFilter.fromQueryParams(params);
      filter.validate();

      var limit = int.tryParse(params['limit'] ?? '') ?? 100;
      var offset = int.tryParse(params['offset'] ?? '') ?? 0;
      if (limit < 1) limit = 1;
      if (limit > maxQueryLimit) limit = maxQueryLimit;
      if (offset < 0) offset = 0;

      final result =
          await repository.query(filter, limit: limit, offset: offset);
      return Response.ok(
        jsonEncode(result.toJson()),
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
    } catch (e, st) {
      return internalError(e, st);
    }
  }
}
