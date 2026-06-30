import 'dart:math';

/// In-memory session tokens for UI authentication.
class SessionStore {
  static const sessionTtl = Duration(hours: 24);

  final _sessions = <String, DateTime>{};
  final Random _random = Random.secure();

  String create() {
    final token = _generateToken();
    _sessions[token] = DateTime.now().add(sessionTtl);
    _purgeExpired();
    return token;
  }

  bool isValid(String? token) {
    if (token == null || token.isEmpty) return false;
    final expiresAt = _sessions[token];
    if (expiresAt == null) return false;
    if (DateTime.now().isAfter(expiresAt)) {
      _sessions.remove(token);
      return false;
    }
    return true;
  }

  void revoke(String? token) {
    if (token == null || token.isEmpty) return;
    _sessions.remove(token);
  }

  void _purgeExpired() {
    final now = DateTime.now();
    _sessions.removeWhere((_, expiresAt) => now.isAfter(expiresAt));
  }

  String _generateToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}