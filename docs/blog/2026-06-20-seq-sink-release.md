---
slug: seq-sink-release
title: SinkSeq — logs Flutter direto no Seq
authors: [altamir]
tags: [seq, clef, observability, release]
date: 2026-06-20T10:00:00
---

A versão **0.1.0** trouxe o `SinkSeq`, permitindo que apps Flutter enviem eventos estruturados em formato CLEF para servidores [Seq](https://datalust.co/seq) — o mesmo ecossistema usado por muitas equipes .NET.

<!--truncate-->

## Por que Seq?

Seq oferece busca poderosa em propriedades estruturadas, dashboards e alertas. Com CLEF, cada log é um documento JSON com campos `@t`, `@mt`, `@l` e propriedades arbitrárias — exatamente o que `LogModel` já produz.

## Uso básico

```dart
final seqSink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'sua-api-key',
  deviceIdentifier: 'checkout-app',
);

logger.addSink(seqSink);

await logger.log(
  'Order {orderId} placed',
  level: LogLevel.info,
  data: {'orderId': 'ORD-991'},
);
```

## Melhorias na 0.1.1 e 0.1.2

As versões seguintes corrigiram detalhes importantes para uso em produção:

- Header `Content-Type: application/vnd.serilog.clef` no POST
- Campos CLEF reservados (`@t`, `@mt`, `@l`, `DeviceIdentifier`) protegidos contra sobrescrita por `data`
- `SinkSeq.close()` para liberar o pool HTTP interno
- Validação de URL em builds de release
- Normalização de URL com trailing slash

## Testabilidade

O construtor aceita um `http.Client` injetado — essencial para testes unitários sem rede:

```dart
SinkSeq(
  'https://seq.test',
  client: mockClient,
);
```

## Saiba mais

Confira o [guia completo de integração com Seq](/guides/seq-integration) na documentação.