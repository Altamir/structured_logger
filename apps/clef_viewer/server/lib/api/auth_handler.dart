import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../auth/secure_compare.dart';
import '../auth/session_store.dart';
import '../config.dart';
import 'errors.dart';

class AuthHandler {
  final AppConfig config;
  final SessionStore sessionStore;

  AuthHandler({required this.config, required this.sessionStore});

  Future<Response> login(Request request) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return const ApiError(
        code: 'BAD_REQUEST',
        message: 'Invalid JSON body',
        status: 400,
      ).toResponse();
    }

    final username = body['username'] as String? ?? '';
    final password = body['password'] as String? ?? '';

    if (!secureEquals(username, config.uiUsername) ||
        !secureEquals(password, config.uiPassword)) {
      return const ApiError(
        code: 'UNAUTHORIZED',
        message: 'Invalid username or password',
        status: 401,
      ).toResponse();
    }

    final token = sessionStore.create();
    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> logout(Request request) async {
    final token = _extractBearerToken(request);
    sessionStore.revoke(token);
    return Response(204);
  }

  static String? _extractBearerToken(Request request) {
    final header = request.headers['Authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7).trim();
    return token.isEmpty ? null : token;
  }
}