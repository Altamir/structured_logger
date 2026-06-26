---
sidebar_position: 3
title: Sink customizado
description: Implemente LogSink para integrar com qualquer destino de log.
---

# Sink customizado

Qualquer destino de log pode ser integrado implementando a interface `LogSink`.

## Interface

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

## Exemplo: sink para arquivo

```dart
import 'dart:convert';
import 'dart:io';

import 'package:structured_logger/structured_logger.dart';

class FileSink extends LogSink {
  FileSink(this.file);

  final File file;

  @override
  Future<void> write(LogModel event) async {
    final line = json.encode(event.toMap());
    await file.writeAsString('$line\n', mode: FileMode.append);
  }
}
```

Uso:

```dart
final logger = StructureLogger();
logger.addSink(FileSink(File('/tmp/app.log')));

await logger.log(
  'Sync completed in {ms}ms',
  level: LogLevel.info,
  data: {'ms': 340},
);
```

## Exemplo: sink com filtro por nível

```dart
class LevelFilterSink extends LogSink {
  LevelFilterSink(this.delegate, {required this.minLevel});

  final LogSink delegate;
  final LogLevel minLevel;

  static const _order = {
    LogLevel.verbose: 0,
    LogLevel.debug: 1,
    LogLevel.info: 2,
    LogLevel.warning: 3,
    LogLevel.error: 4,
  };

  @override
  Future<void> write(LogModel event) async {
    final eventLevel = LogLevel.values.firstWhere(
      (l) => l.sValue == event.level,
      orElse: () => LogLevel.debug,
    );
    if (_order[eventLevel]! >= _order[minLevel]!) {
      await delegate.write(event);
    }
  }
}
```

## Boas práticas

1. **Mantenha `write()` rápido** — operações pesadas (HTTP, disco) podem bloquear quem chama `log()`. Considere enfileirar em background para alto volume.
2. **Não lance exceções não tratadas** — falhas no sink não devem derrubar o app. Capture erros internamente.
3. **Use `LogModel.toMap()`** — serialização consistente com CLEF.
4. **Implemente dispose se necessário** — feche conexões, streams ou clients quando o sink não for mais usado (como `SinkSeq.close()`).

## Registro e remoção

```dart
final sink = FileSink(logFile);
logger.addSink(sink);

// ... mais tarde
logger.removeSink(sink);
```