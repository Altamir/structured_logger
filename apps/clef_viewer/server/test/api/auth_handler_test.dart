import 'dart:convert';

import 'package:clef_viewer_server/api/auth_handler.dart';
import 'package:clef_viewer_server/auth/session_store.dart';
import 'package:clef_viewer_server/config.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late SessionStore sessionStore;
  late AuthHandler auth;

  const config = AppConfig(
    port: 0,
    dbPath: ':memory:',
    maxRows: 1000,
    staticPath: '/nonexistent',
    maxEventBytes: 1024,
    maxBatchEvents: 10,
    maxBatchBytes: 1024,
    uiUsername: 'viewer',
    uiPassword: 'secret',
  );

  setUp(() {
    sessionStore = SessionStore();
    auth = AuthHandler(config: config, sessionStore: sessionStore);
  });

  test('login returns token for valid credentials', () async {
    final response = await auth.login(
      Request(
        'POST',
        Uri.parse('http://localhost/api/auth/login'),
        body: jsonEncode({'username': 'viewer', 'password': 'secret'}),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    final token = body['token'] as String;
    expect(token, isNotEmpty);
    expect(sessionStore.isValid(token), isTrue);
  });

  test('login returns 401 for invalid credentials', () async {
    final response = await auth.login(
      Request(
        'POST',
        Uri.parse('http://localhost/api/auth/login'),
        body: jsonEncode({'username': 'viewer', 'password': 'wrong'}),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    expect(response.statusCode, 401);
  });

  test('logout revokes session token', () async {
    final loginResponse = await auth.login(
      Request(
        'POST',
        Uri.parse('http://localhost/api/auth/login'),
        body: jsonEncode({'username': 'viewer', 'password': 'secret'}),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final token =
        (jsonDecode(await loginResponse.readAsString()) as Map)['token'] as String;

    final logoutResponse = await auth.logout(
      Request(
        'POST',
        Uri.parse('http://localhost/api/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    expect(logoutResponse.statusCode, 204);
    expect(sessionStore.isValid(token), isFalse);
  });
}