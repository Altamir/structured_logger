---
slug: introducing-structured-logger
title: Introduzindo structured_logger para Flutter
authors: [altamir]
tags: [flutter, logging, structured-logging]
date: 2026-06-25T10:00:00
---

Logging em apps Flutter costuma ser uma mistura de `print`, `debugPrint` e strings montadas na hora. Funciona no dia a dia, mas dificulta busca, alertas e correlação quando o app cresce.

<!--truncate-->

## O problema com logs não estruturados

Imagine depurar um problema em produção com a seguinte linha:

```text
User 42 failed to checkout after 3 retries
```

Quem é o usuário 42? Qual foi o erro? Em qual tentativa falhou? Sem campos separados, cada ferramenta de observabilidade precisa fazer parsing frágil de texto livre.

## A abordagem estruturada

Com **structured_logger**, você separa o **template** da mensagem das **propriedades**:

```dart
await logger.log(
  'User {userId} failed checkout after {retries} retries: {error}',
  level: LogLevel.error,
  data: {
    'userId': 42,
    'retries': 3,
    'error': 'payment_timeout',
  },
);
```

O template permanece estável para agrupamento; os dados ficam indexáveis em backends como [Seq](https://datalust.co/seq).

## Sinks: um evento, vários destinos

O diferencial do pacote é o modelo de **sinks**. O mesmo evento pode ir para:

- **Terminal** (`SimpleLineSink`) — leitura rápida durante o desenvolvimento
- **DevTools** (`DefaultSink`) — inspeção no log do desenvolvedor Dart
- **Seq** (`SinkSeq`) — centralização em produção

```dart
final logger = StructureLogger();
logger.addSink(SimpleLineSink());
logger.addSink(SinkSeq('https://seq.example.com', apiKey: apiKey));
```

## Próximos passos

- Leia a [documentação de início rápido](/getting-started/quick-start)
- Explore a [arquitetura de sinks](/concepts/sinks)
- Contribua no [repositório GitHub](https://github.com/Altamir/structured_logger)