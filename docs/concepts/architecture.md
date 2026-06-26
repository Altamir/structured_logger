---
sidebar_position: 1
title: Arquitetura
description: Visão geral do fluxo de dados entre logger, modelo e sinks.
---

# Arquitetura

O pacote segue um modelo simples de **fan-out**: um logger central distribui o mesmo evento estruturado para N destinos independentes.

```
App (código)
    │
    ▼
StructureLogger
    │
    ▼
LogModel ──┬──► SimpleLineSink ──► stdout
           ├──► DefaultSink    ──► dart:developer
           └──► SinkSeq        ──► Servidor Seq
```

## Componentes

### StructureLogger

Ponto de entrada da aplicação. Mantém uma lista interna de `LogSink` e, a cada chamada a `log()`, constrói um `LogModel` e o entrega sequencialmente a cada sink.

```dart
await logger.log(
  'Order {orderId} placed',
  level: LogLevel.info,
  data: {'orderId': 'A-42'},
);
```

### LogModel

Representa um evento estruturado com campos alinhados ao formato [CLEF](https://clef-json.org/):

| Campo | Chave CLEF | Descrição |
|-------|------------|-----------|
| `t` | `@t` | Timestamp ISO-8601 (preenchido automaticamente se vazio) |
| `mt` | `@mt` | Message template com `{placeholders}` |
| `level` | `@l` | Nome do nível (`info`, `warning`, …) |
| `data` | — | Propriedades estruturadas vinculadas ao template |

### LogSink

Contrato mínimo para destinos de saída:

```dart
abstract class LogSink {
  Future<void> write(LogModel event);
}
```

Qualquer integração externa (arquivo, Firebase, Datadog, etc.) implementa essa interface.

## Ciclo de vida dos sinks

- **Registro:** `addSink(sink)` — o sink passa a receber todos os eventos futuros.
- **Remoção:** `removeSink(sink)` — interrompe o recebimento.
- **Dispose (Seq):** `SinkSeq.close()` — libera o pool HTTP interno quando o sink foi criado sem `http.Client` injetado.

## Design intencional

- **Síncrono por sink:** cada `write()` é aguardado em sequência. Isso simplifica o uso, mas sinks lentos (HTTP) podem atrasar a thread que chama `log()`. Uma fila em background está planejada para versões futuras.
- **Mesmo evento para todos:** não há roteamento por nível ou filtro embutido; filtros podem ser implementados dentro de cada sink.