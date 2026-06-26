---
sidebar_position: 5
title: Built-in sinks
description: SimpleLineSink, DefaultSink, and SinkSeq.
---

# Built-in sinks

## SimpleLineSink

```dart
class SimpleLineSink extends LogSink
```

Prints a readable line to the terminal, interpolating `{placeholders}` in `LogModel.mt` with values from `LogModel.data`.

```dart
logger.addSink(SimpleLineSink());
```

---

## DefaultSink

```dart
class DefaultSink extends LogSink
```

Writes the event map (`event.toMap().toString()`) to the Dart developer log via `dart:developer`.

```dart
logger.addSink(DefaultSink());
```

---

## SinkSeq

```dart
class SinkSeq extends LogSink
```

Sends events in CLEF format to a Seq server via HTTP POST.

### Constructor

```dart
SinkSeq(
  String seqUrl, {
  String? apiKey,
  String? deviceIdentifier,
  http.Client? client,
})
```

| Parameter | Description |
|-----------|-------------|
| `seqUrl` | Absolute Seq server URL |
| `apiKey` | Optional API key (`X-Seq-ApiKey` header) |
| `deviceIdentifier` | Identifier included in the CLEF event |
| `client` | Injectable HTTP client for tests |

Throws `ArgumentError` if `seqUrl` is not an absolute URL.

### `close()`

```dart
void close()
```

Closes the internal `http.Client` when no client was injected in the constructor.

### Example

```dart
final sink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'key',
  deviceIdentifier: 'device-1',
);
logger.addSink(sink);

// on dispose
sink.close();
```

See the [Seq integration guide](../guides/seq-integration) for full configuration.