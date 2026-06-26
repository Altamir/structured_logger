---
sidebar_position: 1
title: Console logging
description: Set up readable output and developer log during development.
---

# Console logging

During development, combining `SimpleLineSink` and `DefaultSink` covers most cases.

## Recommended setup

```dart
import 'package:structured_logger/structured_logger.dart';

final logger = StructureLogger();

void setupLogging() {
  // Dart equivalent of kDebugMode (works in pure Dart/CLI/server too)
  const bool kDebugMode = !bool.fromEnvironment('dart.vm.product');
  if (kDebugMode) {
    logger.addSink(SimpleLineSink());
    logger.addSink(DefaultSink());
  }
}
```

- **SimpleLineSink** — quick reading in the terminal (`dart run` or `flutter run`).
- **DefaultSink** — inspection in DevTools / IDE log panel.

**In Flutter only** you may still use `package:flutter/foundation.dart` `kDebugMode` if preferred.

## Log levels

Use `LogLevel` to classify events:

```dart
await logger.log('App started', level: LogLevel.info);
await logger.log('Cache miss for {key}', level: LogLevel.debug, data: {'key': 'user_prefs'});
await logger.log('Retry {attempt} of {max}', level: LogLevel.warning, data: {'attempt': 2, 'max': 5});
await logger.log('Request failed: {error}', level: LogLevel.error, data: {'error': 'timeout'});
await logger.log('Frame {n} rendered', level: LogLevel.verbose, data: {'n': 1204});
```

| Level | Typical use |
|-------|-------------|
| `verbose` | Fine-grained trace, high volume |
| `debug` | Development diagnostics |
| `info` | Normal application flow |
| `warning` | Recoverable or unexpected situation |
| `error` | Failure that deserves attention |

## Tips

- Register sinks once at app startup (e.g. in `main()` after `WidgetsFlutterBinding.ensureInitialized()`).
- In release builds, consider removing `SimpleLineSink` to avoid `print` in production.
- For production, prefer `SinkSeq` or a custom sink that sends to your observability backend.