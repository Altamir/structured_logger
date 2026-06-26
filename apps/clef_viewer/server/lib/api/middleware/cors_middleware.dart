import 'package:shelf/shelf.dart';

/// CORS middleware for cross-origin dev (UI :8080, API :5341).
Middleware corsMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final origin = request.headers['origin'];
      final corsHeaders = <String, String>{
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Content-Type, X-Seq-ApiKey, Accept, Origin',
        'Access-Control-Max-Age': '86400',
      };

      if (origin != null && origin.isNotEmpty) {
        corsHeaders['Access-Control-Allow-Origin'] = origin;
        corsHeaders['Vary'] = 'Origin';
      } else {
        corsHeaders['Access-Control-Allow-Origin'] = '*';
      }

      if (request.method == 'OPTIONS') {
        return Response(204, headers: corsHeaders);
      }

      final response = await inner(request);
      return response.change(headers: corsHeaders);
    };
  };
}