---
slug: introducing-structured-logger
title: Introducing structured_logger for Flutter
authors: [altamir]
tags: [flutter, logging, structured-logging]
date: 2026-06-25T10:00:00
---

Logging in Flutter apps is often a mix of `print`, `debugPrint`, and ad-hoc string concatenation. It works day to day, but makes search, alerts, and correlation harder as the app grows.

<!--truncate-->

## The problem with unstructured logs

Imagine debugging a production issue with this line:

```text
User 42 failed to checkout after 3 retries
```

Who is user 42? What was the error? Which attempt failed? Without separate fields, every observability tool needs fragile free-text parsing.

## The structured approach

With **structured_logger**, you separate the message **template** from **properties**:

```dart
await logger.log(
  'User {userId} failed checkout after {retries} retries: {error}',
  level: LogLevel.error,
  data: {
    'userId': 42,
    'retries': 3,
    'error': 'payment_timeout',
  },
);
```

The template stays stable for grouping; data becomes indexable in backends like [Seq](https://datalust.co/seq).

## Sinks: one event, many destinations

The package's strength is the **sink** model. The same event can go to:

- **Terminal** (`SimpleLineSink`) — quick reading during development
- **DevTools** (`DefaultSink`) — inspection in the Dart developer log
- **Seq** (`SinkSeq`) — centralization in production

```dart
final logger = StructureLogger();
logger.addSink(SimpleLineSink());
logger.addSink(SinkSeq('https://seq.example.com', apiKey: apiKey));
```

## Next steps

- Read the [quick start guide](/getting-started/quick-start)
- Explore [sink architecture](/concepts/sinks)
- Contribute on [GitHub](https://github.com/Altamir/structured_logger)