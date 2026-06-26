import 'package:shelf/shelf.dart';
import 'package:structured_logger/structured_logger.dart';

import '../errors.dart';

Middleware apiKeyMiddleware(
    {required String? expectedKey, required bool required}) {
  return (Handler inner) {
    return (Request request) {
      if (!required && expectedKey == null) {
        return inner(request);
      }

      final provided = request.headers[SEQ_API_KEY];
      if (expectedKey == null) {
        return inner(request);
      }

      if (provided == null || provided.isEmpty) {
        return const ApiError(
          code: 'UNAUTHORIZED',
          message: 'API key required',
          status: 401,
        ).toResponse();
      }

      if (provided != expectedKey) {
        return const ApiError(
          code: 'UNAUTHORIZED',
          message: 'Invalid API key',
          status: 401,
        ).toResponse();
      }

      return inner(request);
    };
  };
}
