---
sidebar_position: 3
title: Custom sink
description: Implement LogSink to integrate with any log destination.
---

# Custom sink

Any log destination can be integrated by implementing the `LogSink` interface.

## Interface

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

## Example: file sink

```dart
import 'dart:convert';
import 'dart:io';

import 'package:structured_logger/structured_logger.dart';

class FileSink extends LogSink {
  FileSink(this.file);

  final File file;

  @override
  Future<void> write(LogModel event) async {
    final line = json.encode(event.toMap());
    await file.writeAsString('$line\n', mode: FileMode.append);
  }
}
```

Usage:

```dart
final logger = StructureLogger();
logger.addSink(FileSink(File('/tmp/app.log')));

await logger.log(
  'Sync completed in {ms}ms',
  level: LogLevel.info,
  data: {'ms': 340},
);
```

## Example: level filter sink

```dart
class LevelFilterSink extends LogSink {
  LevelFilterSink(this.delegate, {required this.minLevel});

  final LogSink delegate;
  final LogLevel minLevel;

  static const _order = {
    LogLevel.verbose: 0,
    LogLevel.debug: 1,
    LogLevel.info: 2,
    LogLevel.warning: 3,
    LogLevel.error: 4,
  };

  @override
  Future<void> write(LogModel event) async {
    final eventLevel = LogLevel.values.firstWhere(
      (l) => l.sValue == event.level,
      orElse: () => LogLevel.debug,
    );
    if (_order[eventLevel]! >= _order[minLevel]!) {
      await delegate.write(event);
    }
  }
}
```

## Best practices

1. **Keep `write()` fast** — heavy work (HTTP, disk) can block the `log()` caller. Consider a background queue for high volume.
2. **Do not throw unhandled exceptions** — sink failures should not crash the app. Catch errors internally.
3. **Use `LogModel.toMap()`** — consistent CLEF serialization.
4. **Implement dispose when needed** — close connections, streams, or clients when done (like `SinkSeq.close()`).

## Register and remove

```dart
final sink = FileSink(logFile);
logger.addSink(sink);

// ... later
logger.removeSink(sink);
```