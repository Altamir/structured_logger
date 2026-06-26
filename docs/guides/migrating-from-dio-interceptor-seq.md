---
sidebar_position: 5
title: Migrando de dio_interceptor_seq
description: Migre do interceptador legado para o novo no monorepo.
---

# Migração de dio_interceptor_seq

O pacote legado `dio_interceptor_seq` é deprecado em favor de `structured_logger` + `structured_logger_dio_interceptor`.

## Antes (legado)

```dart
import 'package:dio/dio.dart';
import 'package:dio_interceptor_seq/dio_interceptor_seq.dart';

final dio = Dio()..interceptors.add(SeqLoggingInterceptor(
  'https://seq.example.com',
  apiKey: 'key',
  deviceIdentifier: 'my-app',
));
```

## Depois (recomendado)

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

## Diferenças principais

- Nomes de pacote e classe mudaram.
- `seqUrl`/`apiKey`/`deviceIdentifier` agora são apenas de `SinkSeq`.
- O interceptor recebe `StructureLogger` (com sinks configurados).
- Mesmos shapes de eventos e templates.
- Sem chamadas diretas a Seq no interceptor.
- Adicione com `dart pub add structured_logger structured_logger_dio_interceptor`.
