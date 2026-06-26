---
sidebar_position: 2
title: Sinks
description: Destinos de saída para eventos de log estruturados.
---

# Sinks

Um **sink** é um destino de saída que implementa `LogSink`. Você pode registrar vários sinks no mesmo `StructureLogger` — cada evento será entregue a todos eles.

## Sinks embutidos

### SimpleLineSink

Imprime uma **linha legível** no terminal, interpolando placeholders do template com valores de `data`:

```dart
logger.addSink(SimpleLineSink());
```

| Entrada | Saída |
|---------|-------|
| `mt: "User {id} logged in"`, `data: {id: 7}` | `User 7 logged in` |

Placeholders sem valor correspondente em `data` são substituídos por string vazia.

### DefaultSink

Envia o evento serializado para o **log do desenvolvedor Dart** (`dart:developer`):

```dart
logger.addSink(DefaultSink());
```

Útil no Flutter DevTools e durante depuração com `flutter run`.

### SinkSeq

Envia eventos em formato **CLEF** para um servidor [Seq](https://datalust.co/seq):

```dart
logger.addSink(SinkSeq(
  'https://seq.example.com',
  apiKey: 'your-api-key',
  deviceIdentifier: 'my-device',
));
```

Consulte o [guia de integração com Seq](../guides/seq-integration) para detalhes de configuração e ciclo de vida.

## Múltiplos sinks

É comum combinar sinks para desenvolvimento e produção:

```dart
final logger = StructureLogger();

const bool kDebugMode = !bool.fromEnvironment('dart.vm.product');
if (kDebugMode) {
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());
}

logger.addSink(SinkSeq(
  seqUrl,
  apiKey: apiKey,
  deviceIdentifier: deviceId,
));
```

## Sink customizado

Implemente `LogSink` e registre com `addSink`. Veja o [guia de sink customizado](../guides/custom-sink).