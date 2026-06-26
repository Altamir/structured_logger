import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';

class LogApiClient {
  final String baseUrl;
  final http.Client _client;

  LogApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  Future<QueryResult> fetchEvents(
    LogFilter filter, {
    int limit = 100,
    int offset = 0,
  }) async {
    final params = filter.toQueryParams()
      ..['limit'] = '$limit'
      ..['offset'] = '$offset';

    final uri = ApiConfig.uri('/api/events', queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch events: ${response.statusCode}');
    }
    return QueryResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<GroupResult>> fetchGroups({
    required String groupBy,
    required LogFilter filter,
    String? bucket,
    String? groupProperty,
  }) async {
    final params = filter.toQueryParams()..['group_by'] = groupBy;
    if (bucket != null) params['bucket'] = bucket;
    if (groupProperty != null) params['group_property'] = groupProperty;

    final uri = ApiConfig.uri('/api/events/group', queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch groups: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = data['groups'] as List<dynamic>;
    return groups
        .map((g) => GroupResult.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<int> deleteLogs({
    LogFilter? filter,
    required String apiKey,
  }) async {
    final params = filter?.toQueryParams() ?? {};
    final uri = ApiConfig.uri(
      '/api/admin/logs',
      queryParameters: params.isEmpty ? null : params,
    );
    final response = await _client.delete(
      uri,
      headers: {'X-Seq-ApiKey': apiKey},
    );
    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['deleted'] as int;
  }

  Future<HealthStatus> fetchHealth() async {
    final uri = ApiConfig.uri('/health');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Health check failed');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return HealthStatus(
      events: data['events'] as int,
      version: data['version'] as String? ?? 'unknown',
    );
  }
}

class HealthStatus {
  final int events;
  final String version;

  HealthStatus({required this.events, required this.version});
}

class UnauthorizedException implements Exception {}