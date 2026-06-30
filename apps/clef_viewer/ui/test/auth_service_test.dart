import 'dart:convert';

import 'package:clef_viewer_ui/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(AuthService.clearToken);

  test('login stores token on success', () async {
    final client = MockClient((request) async {
      expect(request.headers['Content-Type'], 'application/json');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['username'], 'viewer');
      expect(body['password'], 'secret');
      return http.Response(
        jsonEncode({'token': 'session-abc'}),
        200,
        headers: {'Content-Type': 'application/json'},
      );
    });

    await AuthService(client: client).login('viewer', 'secret');

    expect(AuthService.getToken(), 'session-abc');
    expect(AuthService.isAuthenticated, isTrue);
    expect(AuthService.authHeaders(), {'Authorization': 'Bearer session-abc'});
  });

  test('login throws on invalid credentials', () async {
    final client = MockClient((_) async {
      return http.Response('{}', 401);
    });

    expect(
      () => AuthService(client: client).login('viewer', 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
    expect(AuthService.isAuthenticated, isFalse);
  });

  test('logout clears token and calls server', () async {
    AuthService.clearToken();
    await AuthService(client: MockClient((request) async {
      return http.Response(jsonEncode({'token': 'session-abc'}), 200);
    })).login('viewer', 'secret');

    String? logoutAuth;
    final client = MockClient((request) async {
      logoutAuth = request.headers['Authorization'];
      return http.Response('', 204);
    });

    await AuthService(client: client).logout();

    expect(logoutAuth, 'Bearer session-abc');
    expect(AuthService.isAuthenticated, isFalse);
  });

  test('handleUnauthorized clears token and notifies callback', () async {
    await AuthService(client: MockClient((_) async {
      return http.Response(jsonEncode({'token': 'old-token'}), 200);
    })).login('viewer', 'secret');

    var notified = false;
    AuthService.onSessionExpired = () => notified = true;
    AuthService.handleUnauthorized();

    expect(notified, isTrue);
    expect(AuthService.isAuthenticated, isFalse);
    AuthService.onSessionExpired = null;
  });
}