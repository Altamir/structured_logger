---
sidebar_position: 2
title: Início rápido
description: Emita seu primeiro log estruturado em Flutter.
---

# Início rápido

Este guia mostra o fluxo mínimo: criar o logger, registrar sinks e emitir um evento.

## 1. Crie o logger

```dart
final logger = StructureLogger();
```

## 2. Registre sinks

Sinks definem **para onde** os logs vão. Para desenvolvimento local, combine saída legível no terminal com o log do desenvolvedor Dart:

```dart
logger.addSink(SimpleLineSink());
logger.addSink(DefaultSink());
```

## 3. Emita um log

```dart
await logger.log(
  'Welcome {name}, your level is {level}',
  level: LogLevel.info,
  data: {'name': 'John Doe', 'level': 12},
);
```

### O que acontece

1. `StructureLogger` monta um `LogModel` com timestamp ISO-8601, template, nível e `data`.
2. Cada sink registrado recebe o mesmo evento via `write(LogModel)`.
3. `SimpleLineSink` interpola os placeholders e imprime uma linha legível.
4. `DefaultSink` serializa o mapa CLEF e envia para `dart:developer`.

### Saída esperada

```text
Welcome John Doe, your level is 12
[log] {@t: 2026-06-25T10:00:00.000, @mt: Welcome {name}, your level is {level}, @l: info, data: {name: John Doe, level: 12}}
```

## Exemplo completo

```dart
import 'package:flutter/widgets.dart';
import 'package:structured_logger/structured_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = StructureLogger();
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());

  await logger.log(
    'Welcome {name}, your level is {level}',
    level: LogLevel.info,
    data: {'name': 'John Doe', 'level': 12},
  );
}
```

## Próximo passo

- [Sinks](./../concepts/sinks) — entenda o papel de cada destino
- [Integração com Seq](./../guides/seq-integration) — envie logs para produção