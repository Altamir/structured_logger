---
sidebar_position: 1
slug: /
title: Introdução
description: Pacote de logging estruturado para Dart (e Flutter) com sinks plugáveis.
---

# structured_logger

**structured_logger** é um pacote Dart para logging estruturado (com suporte completo a Flutter). Em vez de strings soltas, você emite eventos com **nível**, **template de mensagem** e **propriedades** — e escolhe para onde cada evento vai por meio de **sinks** plugáveis.

## Por que logging estruturado?

Logs estruturados facilitam busca, filtragem e correlação em produção:

- **Templates** com placeholders (`{userId}`, `{duration}`) mantêm a mensagem legível e os dados consultáveis.
- **Níveis** (`info`, `warning`, `error`, …) permitem filtrar ruído.
- **Sinks** desacoplam a emissão do destino: console, `dart:developer`, [Seq](https://datalust.co/seq) ou qualquer backend que você implementar.

## Recursos principais

| Recurso | Descrição |
|---------|-----------|
| `StructureLogger` | Logger central que distribui eventos para todos os sinks registrados |
| `LogSink` | Interface para destinos de saída |
| `SimpleLineSink` | Linha legível no terminal, com interpolação de placeholders |
| `DefaultSink` | Saída no log do desenvolvedor Dart (`dart:developer`) |
| `SinkSeq` | Envio em formato CLEF para servidores Seq |
| `LogModel` | Modelo de evento com campos compatíveis com CLEF (`@t`, `@mt`, `@l`) |

## Requisitos

- Dart SDK `>=3.1.5 <4.0.0`
- Flutter `>=1.17.0`

## Próximos passos

- [Instalação](./getting-started/installation) — adicione o pacote ao seu `pubspec.yaml`
- [Início rápido](./getting-started/quick-start) — primeiro log em poucos minutos
- [Arquitetura](./concepts/architecture) — como logger, modelo e sinks se relacionam
- [Integração com Seq](./guides/seq-integration) — envie logs para um servidor Seq