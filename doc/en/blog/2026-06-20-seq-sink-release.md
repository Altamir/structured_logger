---
slug: seq-sink-release
title: SinkSeq — Flutter logs straight to Seq
authors: [altamir]
tags: [seq, clef, observability, release]
date: 2026-06-20T10:00:00
---

Version **0.1.0** introduced `SinkSeq`, allowing Flutter apps to send structured events in CLEF format to [Seq](https://datalust.co/seq) servers — the same ecosystem many .NET teams already use.

<!--truncate-->

## Why Seq?

Seq offers powerful search over structured properties, dashboards, and alerts. With CLEF, each log is a JSON document with `@t`, `@mt`, `@l`, and arbitrary properties — exactly what `LogModel` already produces.

## Basic usage

```dart
final seqSink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'your-api-key',
  deviceIdentifier: 'checkout-app',
);

logger.addSink(seqSink);

await logger.log(
  'Order {orderId} placed',
  level: LogLevel.info,
  data: {'orderId': 'ORD-991'},
);
```

## Improvements in 0.1.1 and 0.1.2

Later releases fixed important production details:

- `Content-Type: application/vnd.serilog.clef` header on POST
- CLEF reserved fields (`@t`, `@mt`, `@l`, `DeviceIdentifier`) protected from `data` overwrites
- `SinkSeq.close()` to release the internal HTTP pool
- URL validation in release builds
- Trailing slash URL normalization

## Testability

The constructor accepts an injected `http.Client` — essential for unit tests without network:

```dart
SinkSeq(
  'https://seq.test',
  client: mockClient,
);
```

## Learn more

See the full [Seq integration guide](/guides/seq-integration) in the documentation.