---
sidebar_position: 2
title: LogSink
description: Interface abstrata para destinos de saída de log.
---

# LogSink

Interface que define um destino de saída para eventos estruturados.

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

## Contrato

- Recebe um `LogModel` completo a cada chamada.
- Retorna `Future<void>` — pode realizar I/O assíncrono.
- Implementações embutidas: `SimpleLineSink`, `DefaultSink`, `SinkSeq`.

## Quando implementar

Crie um `LogSink` customizado quando precisar enviar logs para:

- Arquivos locais
- Serviços de observabilidade (Datadog, Sentry, CloudWatch, etc.)
- Bancos de dados ou filas de mensagens
- Qualquer API HTTP proprietária

Veja o [guia de sink customizado](../guides/custom-sink).