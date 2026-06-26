---
sidebar_position: 1
title: Architecture
description: Overview of the data flow between logger, model, and sinks.
---

# Architecture

The package follows a simple **fan-out** model: a central logger distributes the same structured event to N independent destinations.

```
App (code)
    │
    ▼
StructureLogger
    │
    ▼
LogModel ──┬──► SimpleLineSink ──► stdout
           ├──► DefaultSink    ──► dart:developer
           └──► SinkSeq        ──► Seq server
```

## Components

### StructureLogger

Application entry point. Keeps an internal list of `LogSink` instances and, on each `log()` call, builds a `LogModel` and delivers it sequentially to every sink.

```dart
await logger.log(
  'Order {orderId} placed',
  level: LogLevel.info,
  data: {'orderId': 'A-42'},
);
```

### LogModel

Represents a structured event with fields aligned to [CLEF](https://clef-json.org/):

| Field | CLEF key | Description |
|-------|----------|-------------|
| `t` | `@t` | ISO-8601 timestamp (auto-filled when empty) |
| `mt` | `@mt` | Message template with `{placeholders}` |
| `level` | `@l` | Level name (`info`, `warning`, …) |
| `data` | — | Structured properties bound to the template |

### LogSink

Minimal contract for output destinations:

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

Any external integration (file, Firebase, Datadog, etc.) implements this interface.

## Sink lifecycle

- **Register:** `addSink(sink)` — the sink receives all future events.
- **Remove:** `removeSink(sink)` — stops delivery.
- **Dispose (Seq):** `SinkSeq.close()` — releases the internal HTTP pool when no `http.Client` was injected.

## Design notes

- **Sequential per sink:** each `write()` is awaited in order. This keeps usage simple, but slow sinks (HTTP) may delay the caller. A background queue is planned for future versions.
- **Same event for all:** there is no built-in level routing or filtering; implement that inside each sink if needed.