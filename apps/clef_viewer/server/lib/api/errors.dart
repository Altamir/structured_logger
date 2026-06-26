import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Standard API error envelope.
class ApiError {
  final String code;
  final String message;
  final int status;

  const ApiError({
    required this.code,
    required this.message,
    required this.status,
  });

  Response toResponse() {
    if (status >= 500) {
      stderr.writeln('API error [$code]: $message');
    }
    return Response(
      status,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Response internalError([Object? error, StackTrace? stack]) {
  if (error != null) {
    stderr.writeln('Internal error: $error');
    if (stack != null) stderr.writeln(stack);
  }
  return const ApiError(
    code: 'INTERNAL_ERROR',
    message: 'Internal server error',
    status: 500,
  ).toResponse();
}