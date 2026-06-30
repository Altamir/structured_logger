import 'package:shelf/shelf.dart';

import '../../auth/session_store.dart';
import '../errors.dart';

Middleware sessionMiddleware({required SessionStore sessionStore}) {
  return (Handler inner) {
    return (Request request) {
      final token = _extractToken(request);
      if (!sessionStore.isValid(token)) {
        return const ApiError(
          code: 'UNAUTHORIZED',
          message: 'Session required',
          status: 401,
        ).toResponse();
      }
      return inner(request);
    };
  };
}

String? _extractToken(Request request) {
  final header = request.headers['Authorization'];
  if (header != null && header.startsWith('Bearer ')) {
    final token = header.substring(7).trim();
    if (token.isNotEmpty) return token;
  }

  final queryToken = request.url.queryParameters['access_token'];
  if (queryToken != null && queryToken.isNotEmpty) {
    return queryToken;
  }

  return null;
}