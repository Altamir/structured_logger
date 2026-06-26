---
sidebar_position: 2
title: Seq integration
description: Send structured logs in CLEF format to a Seq server.
---

# Seq integration

[Seq](https://datalust.co/seq) is a structured log server compatible with **CLEF** (Compact Log Event Format). The package includes `SinkSeq` to send events directly from Flutter.

## Basic setup

```dart
final seqSink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'your-api-key',
  deviceIdentifier: 'app-mobile-v1',
);

logger.addSink(seqSink);
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `seqUrl` | Yes | Absolute URL of the Seq server |
| `apiKey` | No | Key sent in the `X-Seq-ApiKey` header |
| `deviceIdentifier` | No | Device identifier in the CLEF event |
| `client` | No | Injected `http.Client` (useful in tests) |

## Endpoint and format

The sink sends `POST` to:

```text
{seqUrl}/api/events/raw?clef
```

- **Content-Type:** `application/vnd.serilog.clef`
- **Body:** one CLEF JSON object per request

Reserved fields in the event:

- `@t` — timestamp
- `@mt` — message template
- `@l` — level
- `DeviceIdentifier` — device identifier

`data` properties are merged without overwriting reserved fields.

## Lifecycle

When `SinkSeq` creates the `http.Client` internally, call `close()` when discarding the sink in long-lived apps:

```dart
@override
void dispose() {
  seqSink.close();
  super.dispose();
}
```

If you inject a custom `client`, the sink **does not** close it — lifecycle stays with the creator.

## Error handling

Network failures or HTTP responses outside 200–201 are logged with `print` **only in debug mode** (using `!bool.fromEnvironment('dart.vm.product')`). In release, failures are silent to avoid impacting UX. (Flutter apps may equivalently use `kDebugMode`.)

## Trailing slash URLs

URLs with a trailing slash are normalized correctly when building the endpoint (`Uri.resolve`).

## URL validation

`seqUrl` must be an absolute URL. Invalid URLs throw `ArgumentError` in all builds (including release).

## Example with multiple sinks

```dart
final logger = StructureLogger();

logger.addSink(SimpleLineSink()); // dev
logger.addSink(SinkSeq(
  'https://seq.example.com',
  apiKey: const String.fromEnvironment('SEQ_API_KEY'),
  deviceIdentifier: 'checkout-app',
));
```

## Tests

Inject a mock `http.Client` to verify requests without a real network. See `test/log_sinks/sink_seq_test.dart` in the repository.