import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_storage_stub.dart'
    if (dart.library.html) 'auth_storage_web.dart' as auth_storage;

typedef SessionExpiredCallback = void Function();

class AuthService {
  static SessionExpiredCallback? onSessionExpired;

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static String? getToken() => auth_storage.readAuthStorage(
        ApiConfig.sessionTokenStorageKey,
      );

  static bool get isAuthenticated {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String username, String password) async {
    final uri = ApiConfig.uri('/api/auth/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 401) {
      throw InvalidCredentialsException();
    }
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login response missing token');
    }
    auth_storage.writeAuthStorage(ApiConfig.sessionTokenStorageKey, token);
  }

  Future<void> logout() async {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      final uri = ApiConfig.uri('/api/auth/logout');
      try {
        await _client.post(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // Best-effort server logout; always clear local session.
      }
    }
    clearToken();
  }

  static void clearToken() {
    auth_storage.removeAuthStorage(ApiConfig.sessionTokenStorageKey);
  }

  static void handleUnauthorized() {
    clearToken();
    onSessionExpired?.call();
  }

  static Map<String, String> authHeaders() {
    final token = getToken();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }
}

class InvalidCredentialsException implements Exception {}