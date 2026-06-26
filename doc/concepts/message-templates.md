---
sidebar_position: 3
title: Templates de mensagem
description: Como usar placeholders e propriedades estruturadas nos logs.
---

# Templates de mensagem

O parâmetro `message` de `StructureLogger.log()` é um **message template**: texto com placeholders `{nome}` que serão preenchidos a partir de `data`.

## Sintaxe

```dart
await logger.log(
  'Payment {status} for order {orderId} — amount {amount}',
  level: LogLevel.info,
  data: {
    'status': 'approved',
    'orderId': 'ORD-991',
    'amount': 149.90,
  },
);
```

- O template fica armazenado em `LogModel.mt` (campo `@mt` no CLEF).
- As propriedades ficam em `LogModel.data`, separadas da mensagem renderizada.
- Ferramentas como Seq indexam `data` para busca e dashboards.

## Interpolação no SimpleLineSink

`SimpleLineSink` usa a regex `\{(.*?)\}` para substituir cada placeholder pelo valor correspondente em `data`:

```dart
// Template: "Hello {name}"
// data: {name: "Ana"}
// Resultado: "Hello Ana"
```

Valores são convertidos com `.toString()`. Chaves ausentes em `data` produzem substituição vazia.

## Boas práticas

1. **Use nomes descritivos** — `{userId}` em vez de `{id}` quando houver ambiguidade.
2. **Mantenha o template estável** — facilita agrupamento e alertas em backends estruturados.
3. **Coloque dados variáveis em `data`** — evite concatenar strings manualmente no template.
4. **Evite dados sensíveis** — senhas e tokens não devem aparecer em `data` se os logs forem exportados.

## Compatibilidade com CLEF

O modelo segue a convenção Serilog/CLEF:

```json
{
  "@t": "2026-06-25T10:00:00.000",
  "@mt": "Payment {status} for order {orderId}",
  "@l": "info",
  "status": "approved",
  "orderId": "ORD-991"
}
```

No `SinkSeq`, propriedades de `data` são mescladas no evento CLEF, enquanto `@t`, `@mt`, `@l` e `DeviceIdentifier` são reservados e não podem ser sobrescritos acidentalmente por chaves em `data`.