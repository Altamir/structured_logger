---
sidebar_position: 4
title: Interceptador Dio
description: Registre HTTP com DioLoggingInterceptor + StructureLogger + sinks.
---

# Logging HTTP com Dio

Use `DioLoggingInterceptor` para emitir Log Events estruturados de requisições, respostas e erros HTTP. Ele delega para um `StructureLogger` já configurado (e seus sinks como `SinkSeq`).

## Configuração

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

## Comportamento

- `onRequest`: gera UUID correlacional (header padrão `X-Request-Seq-Id`), define `X-Request-Start-Time`, emite evento `REQUEST`.
- `onResponse`: emite `RESPONSE` com `statusCode`, `elapsedTime` (ms), headers, data.
- `onError`: emite `ON_ERROR` (nível error) com status opcional e dados de erro.

Todos os eventos passam pelos sinks registrados — sem HTTP direto do interceptor.

## Construtor

```dart
DioLoggingInterceptor(
  this._logger, {
  this.correlationalHeaderName = 'X-Request-Seq-Id',
})
```

- `correlationalHeaderName` não pode ser vazio (assert).
- `deviceIdentifier` fica em `SinkSeq`.
