# structured_logger

Structured logging for Dart with pluggable CLEF-compatible sinks.

This package provides an easy way to implement structured logs in Dart and Flutter applications. It allows sending logs to different destinations (terminal, Seq, etc.) through pluggable `Sink` interfaces.

## Features

- Pure Dart (works in CLI, servers, Flutter, etc.)
- Message templates with placeholders (e.g. `User {userId} logged in`)
- Multiple sinks: console, Seq (CLEF), custom
- Dio interceptor support (via companion package)
- Full CLEF / Seq compatibility

## Installation

```bash
dart pub add structured_logger
```

For Flutter:

```bash
flutter pub add structured_logger
```

## Quick Start

```dart
import 'package:structured_logger/structured_logger.dart';

final logger = StructureLogger()
  ..addSink(SimpleLineSink()); // console output

await logger.info('User {userId} did {action}', data: {
  'userId': 42,
  'action': 'checkout',
});
```

## Sinks

- `SimpleLineSink` – human readable console logs
- `SinkSeq` – send to Seq (or any CLEF-compatible collector)
- Custom sinks by implementing `LogSink`

Example with Seq:

```dart
logger.addSink(SinkSeq(
  'https://your-seq-server',
  apiKey: 'your-key',
  deviceIdentifier: 'my-app',
));
```

## Documentation

Full documentation, guides and API reference:

- https://structured-logger.altamir.dev

## Related Packages

- [structured_logger_dio_interceptor](https://pub.dev/packages/structured_logger_dio_interceptor) – Dio HTTP logging

## License

MIT License. See [LICENSE](LICENSE) for details.