---
sidebar_position: 2
title: Integração com Seq
description: Envie logs estruturados em CLEF para um servidor Seq.
---

# Integração com Seq

[Seq](https://datalust.co/seq) é um servidor de logs estruturados compatível com o formato **CLEF** (Compact Log Event Format). O pacote inclui `SinkSeq` para enviar eventos diretamente do Flutter.

## Configuração básica

```dart
final seqSink = SinkSeq(
  'https://seq.example.com',
  apiKey: 'sua-api-key',
  deviceIdentifier: 'app-mobile-v1',
);

logger.addSink(seqSink);
```

### Parâmetros

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `seqUrl` | Sim | URL absoluta do servidor Seq |
| `apiKey` | Não | Chave enviada no header `X-Seq-ApiKey` |
| `deviceIdentifier` | Não | Identificador do dispositivo no evento CLEF |
| `client` | Não | `http.Client` injetado (útil em testes) |

## Endpoint e formato

O sink envia `POST` para:

```text
{seqUrl}/api/events/raw?clef
```

- **Content-Type:** `application/vnd.serilog.clef`
- **Corpo:** um objeto JSON CLEF por requisição

Campos reservados no evento:

- `@t` — timestamp
- `@mt` — message template
- `@l` — nível
- `DeviceIdentifier` — identificador do dispositivo

Propriedades de `data` são mescladas no evento sem sobrescrever os campos reservados.

## Ciclo de vida

Quando `SinkSeq` cria o `http.Client` internamente, chame `close()` ao descartar o sink em apps de longa duração:

```dart
@override
void dispose() {
  seqSink.close();
  super.dispose();
}
```

Se você injetar um `client` customizado, o sink **não** fecha esse client — o controle do ciclo de vida fica com quem o criou.

## Tratamento de erros

Falhas de rede ou respostas HTTP fora do intervalo 200–201 são registradas com `print` **apenas em modo debug** (usando `!bool.fromEnvironment('dart.vm.product')`). Em release, falhas são silenciosas para não impactar a UX. (Apps Flutter podem usar `kDebugMode` equivalentemente.)

## URL com barra final

URLs com trailing slash são normalizadas corretamente na construção do endpoint (`Uri.resolve`).

## Validação de URL

`seqUrl` deve ser uma URL absoluta. URLs inválidas lançam `ArgumentError` em todos os builds (incluindo release).

## Exemplo com múltiplos sinks

```dart
final logger = StructureLogger();

logger.addSink(SimpleLineSink()); // dev
logger.addSink(SinkSeq(
  'https://seq.example.com',
  apiKey: const String.fromEnvironment('SEQ_API_KEY'),
  deviceIdentifier: 'checkout-app',
));
```

## Testes

Injete um `http.Client` mock para verificar requisições sem rede real. O repositório inclui testes em `test/log_sinks/sink_seq_test.dart` como referência.