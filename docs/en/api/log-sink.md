---
sidebar_position: 2
title: LogSink
description: Abstract interface for log output destinations.
---

# LogSink

Interface that defines an output destination for structured events.

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

## Contract

- Receives a complete `LogModel` on each call.
- Returns `Future<void>` — may perform async I/O.
- Built-in implementations: `SimpleLineSink`, `DefaultSink`, `SinkSeq`.

## When to implement

Create a custom `LogSink` when you need to send logs to:

- Local files
- Observability services (Datadog, Sentry, CloudWatch, etc.)
- Databases or message queues
- Any proprietary HTTP API

See the [custom sink guide](../guides/custom-sink).