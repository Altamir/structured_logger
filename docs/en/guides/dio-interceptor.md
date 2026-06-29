---
sidebar_position: 4
title: Dio interceptor
description: Log HTTP with DioLoggingInterceptor + StructureLogger + sinks.
---

# Dio HTTP logging

Use `DioLoggingInterceptor` to emit structured Log Events for HTTP requests, responses and errors. It delegates to a pre-configured `StructureLogger` (and its sinks such as `SinkSeq`).

## Setup

```dart
import 'package:dio/dio.dart';
import 'package:structured_logger/structured_logger.dart';
import 'package:structured_logger_dio_interceptor/structured_logger_dio_interceptor.dart';

final logger = StructureLogger()
  ..addSink(SinkSeq(
    'https://your-seq.example.com',
    apiKey: 'your-api-key',
    deviceIdentifier: 'my-app',
  ));

final dio = Dio()..interceptors.add(DioLoggingInterceptor(logger));
```

## Behavior

- `onRequest`: generates correlational UUID (default header `X-Request-Seq-Id`), sets `X-Request-Start-Time`, emits `REQUEST` event.
- `onResponse`: emits `RESPONSE` with `statusCode`, `elapsedTime` (ms), headers, data.
- `onError`: emits `ON_ERROR` (level error) with optional status and error data.

All events go through your registered sinks — no direct HTTP from the interceptor.

## Constructor

```dart
DioLoggingInterceptor(
  this._logger, {
  this.correlationalHeaderName = 'X-Request-Seq-Id',
  this.deviceHeaderName = 'X-device-id',
})
```

- `correlationalHeaderName` and `deviceHeaderName` must be non-empty.
- Default `deviceIdentifier` lives on `SinkSeq`; when the request includes the `X-device-id` header (or the name set in `deviceHeaderName`), that value becomes the event `DeviceIdentifier`. Without the header, `SinkSeq.deviceIdentifier` is used.

## Templates and properties

Message templates use `{property}` placeholders aligned with `StructureLogger` (not `{@property}`).

- REQUEST: `REQUEST: {method} {path} {correlationalSeqID} {queryParams} {headers}`
- RESPONSE: `RESPONSE: {statusCode} {path} {correlationalSeqID} {headers} {elapsedTime}`
- ERROR: `ERROR: {statusCode} {path} {correlationalSeqID} {message} {headers} {elapsedTime}`

Request/response bodies are **not** part of `@mt`; they are emitted as structured properties (`data`, `errorData`) for search and inspection in the viewer.

See the package source for the full property map (`event_type`, `elapsedTime`, etc.).
