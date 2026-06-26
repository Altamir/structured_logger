---
sidebar_position: 1
title: StructureLogger
description: Logger central que distribui eventos para sinks registrados.
---

# StructureLogger

Classe principal do pacote. Centraliza a emissão de logs e distribui cada evento para todos os `LogSink` registrados.

## Construtor

```dart
StructureLogger()
```

Cria um logger vazio, sem sinks.

## Métodos

### `log`

```dart
Future<void> log(
  String message, {
  LogLevel level = LogLevel.info,
  Map<String, dynamic>? data,
})
```

Emite um evento estruturado.

| Parâmetro | Descrição |
|-----------|-----------|
| `message` | Message template com placeholders `{chave}` |
| `level` | Nível do evento (padrão: `LogLevel.info`) |
| `data` | Propriedades vinculadas aos placeholders |

Internamente constrói um `LogModel` e chama `write()` em cada sink, aguardando cada um em sequência.

### `addSink`

```dart
void addSink(LogSink sink)
```

Registra um sink. Eventos emitidos **após** o registro serão entregues a ele.

### `removeSink`

```dart
void removeSink(LogSink sink)
```

Remove um sink da lista. Eventos futuros não serão mais entregues a ele.

## Exemplo

```dart
final logger = StructureLogger();
logger.addSink(SimpleLineSink());

await logger.log(
  'Session {sessionId} created',
  level: LogLevel.info,
  data: {'sessionId': 'abc-123'},
);
```