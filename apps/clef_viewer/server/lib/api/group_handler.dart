import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../db/log_repository.dart';
import '../models/group_result.dart';
import '../models/log_filter.dart';
import 'errors.dart';

class GroupHandler {
  final LogRepository repository;

  GroupHandler({required this.repository});

  Future<Response> handle(Request request) async {
    try {
      final params = Map<String, String>.from(request.url.queryParameters);
      final groupByParam = params['group_by'];
      if (groupByParam == null || groupByParam.isEmpty) {
        return const ApiError(
          code: 'INVALID_REQUEST',
          message: 'group_by parameter is required',
          status: 400,
        ).toResponse();
      }

      final groupBy = GroupByParsing.fromString(groupByParam);
      if (groupBy == null) {
        return const ApiError(
          code: 'INVALID_REQUEST',
          message: 'Unknown group_by value',
          status: 400,
        ).toResponse();
      }

      TimeBucket? bucket;
      if (groupBy == GroupBy.time) {
        final bucketParam = params['bucket'] ?? 'hour';
        bucket = TimeBucketParsing.fromString(bucketParam);
        if (bucket == null) {
          return const ApiError(
            code: 'INVALID_REQUEST',
            message: 'Invalid bucket value',
            status: 400,
          ).toResponse();
        }
      }

      String? propertyName;
      if (groupBy == GroupBy.property) {
        propertyName = params['group_property'];
        if (propertyName == null || propertyName.isEmpty) {
          final legacy = params['property'];
          if (legacy != null &&
              legacy.isNotEmpty &&
              !legacy.contains('=')) {
            propertyName = legacy;
          }
        }
        if (propertyName == null || propertyName.isEmpty) {
          return const ApiError(
            code: 'INVALID_REQUEST',
            message:
                'group_property parameter is required for group_by=property',
            status: 400,
          ).toResponse();
        }
      }

      final filter = LogFilter.fromQueryParams(params);
      filter.validate();

      final groups = await repository.group(
        filter,
        groupBy,
        bucket: bucket,
        propertyName: propertyName,
      );

      return Response.ok(
        jsonEncode({
          'groups': groups.map((g) => g.toJson()).toList(),
        }),
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