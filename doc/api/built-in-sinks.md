---
sidebar_position: 5
title: Sinks embutidos
description: SimpleLineSink, DefaultSink e SinkSeq.
---

# Sinks embutidos

## SimpleLineSink

```dart
class SimpleLineSink extends LogSink
```

Imprime uma linha legível no terminal, interpolando `{placeholders}` de `LogModel.mt` com valores de `LogModel.data`.

```dart
logger.addSink(SimpleLineSink());
```

---

## DefaultSink

```dart
class DefaultSink extends LogSink
```

Escreve o mapa do evento (`event.toMap().toString()`) no log do desenvolvedor Dart via `dart:developer`.

```dart
logger.addSink(DefaultSink());
```

---

## SinkSeq

```dart
class SinkSeq extends LogSink
```

Envia eventos em formato CLEF para um servidor Seq via HTTP POST.

### Construtor

```dart
SinkSeq(
  String seqUrl, {
  String? apiKey,
  String? deviceIdentifier,
  http.Client? client,
})
```

| Parâmetro | Descrição |
|-----------|-----------|
| `seqUrl` | URL absoluta do servidor Seq |
| `apiKey` | API key opcional (header `X-Seq-ApiKey`) |
| `deviceIdentifier` | Identificador incluído no evento CLEF |
| `client` | Client HTTP injetável para testes |

Lança `ArgumentError` se `seqUrl` não for uma URL absoluta.

### `close()`

```dart
void close()
```

Fecha o `http.Client` interno quando nenhum client foi injetado no construtor.

### Exemplo

```dart
final sink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'key',
  deviceIdentifier: 'device-1',
);
logger.addSink(sink);

// ao descartar
sink.close();
```

Consulte o [guia de integração com Seq](../guides/seq-integration) para configuração completa.