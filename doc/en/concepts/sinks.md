---
sidebar_position: 2
title: Sinks
description: Output destinations for structured log events.
---

# Sinks

A **sink** is an output destination that implements `LogSink`. You can register multiple sinks on the same `StructureLogger` — every event is delivered to all of them.

## Built-in sinks

### SimpleLineSink

Prints a **readable line** to the terminal, interpolating template placeholders from `data`:

```dart
logger.addSink(SimpleLineSink());
```

| Input | Output |
|-------|--------|
| `mt: "User {id} logged in"`, `data: {id: 7}` | `User 7 logged in` |

Placeholders without a matching key in `data` are replaced with an empty string.

### DefaultSink

Sends the serialized event to the **Dart developer log** (`dart:developer`):

```dart
logger.addSink(DefaultSink());
```

Useful in Flutter DevTools and during `flutter run` debugging.

### SinkSeq

Sends events in **CLEF** format to a [Seq](https://datalust.co/seq) server:

```dart
logger.addSink(SinkSeq(
  'https://seq.example.com',
  apiKey: 'your-api-key',
  deviceIdentifier: 'my-device',
));
```

See the [Seq integration guide](../guides/seq-integration) for configuration and lifecycle details.

## Multiple sinks

It is common to combine sinks for development and production:

```dart
final logger = StructureLogger();

if (kDebugMode) {
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());
}

logger.addSink(SinkSeq(
  seqUrl,
  apiKey: apiKey,
  deviceIdentifier: deviceId,
));
```

## Custom sink

Implement `LogSink` and register with `addSink`. See the [custom sink guide](../guides/custom-sink).