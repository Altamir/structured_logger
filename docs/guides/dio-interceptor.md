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
  this.deviceHeaderName = 'X-device-id',
})
```

- `correlationalHeaderName` e `deviceHeaderName` não podem ser vazios.
- `deviceIdentifier` padrão fica em `SinkSeq`; quando a requisição inclui o header `X-device-id` (ou o nome configurado em `deviceHeaderName`), esse valor é usado como `DeviceIdentifier` do evento. Sem o header, vale o `deviceIdentifier` do `SinkSeq`.

## Templates e properties

Os message templates usam placeholders `{propriedade}` alinhados ao `StructureLogger` (não `{@propriedade}`).

- REQUEST: `REQUEST: {method} {path} {correlationalSeqID} {headers}`
- RESPONSE: `RESPONSE: {statusCode} {path} {correlationalSeqID} {headers} {elapsedTime}`
- ERROR: `ERROR: {statusCode} {path} {correlationalSeqID} {message} {headers} {elapsedTime}`

Cada query parameter do request é emitido como property de nível superior `queryParam.<nome>` (ex.: `queryParam.page=1`), permitindo filtros no CLEF Viewer.

Tokens JWT em headers, query params e body são ofuscados nos logs (`eyJhbG...***`); os headers originais da requisição Dio não são alterados.

Corpos de request/response **não** fazem parte do `@mt`; são emitidos como properties estruturadas (`data`, `errorData`) para busca e inspeção no viewer.

Veja o código do pacote para o mapa completo de properties (`event_type`, `elapsedTime`, etc.).
