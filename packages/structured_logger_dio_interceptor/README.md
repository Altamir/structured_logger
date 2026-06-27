# structured_logger_dio_interceptor

Dio interceptor that emits structured Log Events using a pre-configured `StructureLogger`.

This package lets you log HTTP requests/responses/errors from Dio in a structured way (templates + properties) so they can be sent to any sink (console, Seq, etc.).

## Installation

```bash
dart pub add structured_logger_dio_interceptor
```

It depends on `structured_logger` (add both if not already present).

## Usage

```dart
import 'package:structured_logger/structured_logger.dart';
import 'package:structured_logger_dio_interceptor/structured_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';

final logger = StructureLogger()
  ..addSink(SimpleLineSink())
  ..addSink(SinkSeq('https://your-seq'));

final dio = Dio();
dio.interceptors.add(DioLoggingInterceptor(logger));

await dio.get('https://example.com');
```

Events emitted:
- REQUEST
- RESPONSE
- ON_ERROR

Each event contains rich structured data (url, method, status, headers, body, duration, etc.).

## Documentation

See the main package documentation:

https://structured-logger.altamir.dev

## License

MIT License. See [LICENSE](LICENSE) for details.