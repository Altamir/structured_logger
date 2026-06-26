---
sidebar_position: 2
title: Quick start
description: Emit your first structured log in Flutter.
---

# Quick start

This guide covers the minimum flow: create the logger, register sinks, and emit an event.

## 1. Create the logger

```dart
final logger = StructureLogger();
```

## 2. Register sinks

Sinks define **where** logs go. For local development, combine readable terminal output with the Dart developer log:

```dart
logger.addSink(SimpleLineSink());
logger.addSink(DefaultSink());
```

## 3. Emit a log

```dart
await logger.log(
  'Welcome {name}, your level is {level}',
  level: LogLevel.info,
  data: {'name': 'John Doe', 'level': 12},
);
```

### What happens

1. `StructureLogger` builds a `LogModel` with an ISO-8601 timestamp, template, level, and `data`.
2. Each registered sink receives the same event via `write(LogModel)`.
3. `SimpleLineSink` interpolates placeholders and prints a readable line.
4. `DefaultSink` serializes the CLEF map and sends it to `dart:developer`.

### Expected output

```text
Welcome John Doe, your level is 12
[log] {@t: 2026-06-25T10:00:00.000, @mt: Welcome {name}, your level is {level}, @l: info, data: {name: John Doe, level: 12}}
```

## Full example

```dart
import 'package:flutter/widgets.dart';
import 'package:structured_logger/structured_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = StructureLogger();
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());

  await logger.log(
    'Welcome {name}, your level is {level}',
    level: LogLevel.info,
    data: {'name': 'John Doe', 'level': 12},
  );
}
```

## Next step

- [Sinks](../concepts/sinks) — understand each destination
- [Seq integration](../guides/seq-integration) — send logs to production