---
sidebar_position: 5
title: Migrating from dio_interceptor_seq
description: Move from legacy SeqLoggingInterceptor to the monorepo DioLoggingInterceptor.
---

# Migration from dio_interceptor_seq

The legacy package `dio_interceptor_seq` is deprecated in favor of `structured_logger` + `structured_logger_dio_interceptor`.

## Before (legacy)

```dart
import 'package:dio/dio.dart';
import 'package:dio_interceptor_seq/dio_interceptor_seq.dart';

final dio = Dio()..interceptors.add(SeqLoggingInterceptor(
  'https://seq.example.com',
  apiKey: 'key',
  deviceIdentifier: 'my-app',
  correlationalHeaderName: 'X-Request-Seq-Id',
));
```

## After (recommended)

```dart
import 'package:dio/dio.dart';
import 'package:structured_logger/structured_logger.dart';
import 'package:structured_logger_dio_interceptor/structured_logger_dio_interceptor.dart';

final logger = StructureLogger()
  ..addSink(SinkSeq(
    'https://seq.example.com',
    apiKey: 'key',
    deviceIdentifier: 'my-app',
  ));

final dio = Dio()..interceptors.add(DioLoggingInterceptor(logger));
```

## Key differences

- Package + class names changed.
- `seqUrl` / `apiKey` / `deviceIdentifier` now belong exclusively to `SinkSeq`.
- Interceptor receives `StructureLogger` (already wired to any sinks you want).
- Same event shapes (`REQUEST`/`RESPONSE`/`ON_ERROR`), templates and headers.
- No direct Seq calls from interceptor; fully decoupled.
- Use `dart pub add structured_logger structured_logger_dio_interceptor`.

## In monorepo context

See `packages/structured_logger_dio_interceptor` and the Dio guide for details.
