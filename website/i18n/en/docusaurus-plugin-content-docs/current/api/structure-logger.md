---
sidebar_position: 1
title: StructureLogger
description: Central logger that distributes events to registered sinks.
---

# StructureLogger

Main package class. Centralizes log emission and distributes each event to all registered `LogSink` instances.

## Constructor

```dart
StructureLogger()
```

Creates an empty logger with no sinks.

## Methods

### `log`

```dart
Future<void> log(
  String message, {
  LogLevel level = LogLevel.info,
  Map<String, dynamic>? data,
})
```

Emits a structured event.

| Parameter | Description |
|-----------|-------------|
| `message` | Message template with `{key}` placeholders |
| `level` | Event level (default: `LogLevel.info`) |
| `data` | Properties bound to placeholders |

Internally builds a `LogModel` and calls `write()` on each sink sequentially.

### `addSink`

```dart
void addSink(LogSink sink)
```

Registers a sink. Events emitted **after** registration are delivered to it.

### `removeSink`

```dart
void removeSink(LogSink sink)
```

Removes a sink. Future events are no longer delivered to it.

## Example

```dart
final logger = StructureLogger();
logger.addSink(SimpleLineSink());

await logger.log(
  'Session {sessionId} created',
  level: LogLevel.info,
  data: {'sessionId': 'abc-123'},
);
```