---
sidebar_position: 1
title: Logging no console
description: Configure saída legível e log do desenvolvedor durante o desenvolvimento.
---

# Logging no console

Durante o desenvolvimento, a combinação de `SimpleLineSink` e `DefaultSink` cobre a maioria dos casos.

## Configuração recomendada

```dart
import 'package:structured_logger/structured_logger.dart';

final logger = StructureLogger();

void setupLogging() {
  // Equivalente Dart ao kDebugMode (funciona em Dart puro/CLI/server também)
  const bool kDebugMode = !bool.fromEnvironment('dart.vm.product');
  if (kDebugMode) {
    logger.addSink(SimpleLineSink());
    logger.addSink(DefaultSink());
  }
}
```

- **SimpleLineSink** — leitura rápida no terminal (`dart run` ou `flutter run`).
- **DefaultSink** — inspeção no DevTools / painel de logs do IDE.

**Somente em Flutter** você pode continuar usando `kDebugMode` de `package:flutter/foundation.dart` se preferir.

## Níveis de log

Use `LogLevel` para classificar eventos:

```dart
await logger.log('App started', level: LogLevel.info);
await logger.log('Cache miss for {key}', level: LogLevel.debug, data: {'key': 'user_prefs'});
await logger.log('Retry {attempt} of {max}', level: LogLevel.warning, data: {'attempt': 2, 'max': 5});
await logger.log('Request failed: {error}', level: LogLevel.error, data: {'error': 'timeout'});
await logger.log('Frame {n} rendered', level: LogLevel.verbose, data: {'n': 1204});
```

| Nível | Uso típico |
|-------|------------|
| `verbose` | Traço fino, alto volume |
| `debug` | Diagnóstico de desenvolvimento |
| `info` | Fluxo normal da aplicação |
| `warning` | Situação recuperável ou inesperada |
| `error` | Falha que merece atenção |

## Dicas

- Registre sinks uma vez na inicialização do app (por exemplo, em `main()` após `WidgetsFlutterBinding.ensureInitialized()`).
- Em builds de release, considere remover `SimpleLineSink` para evitar `print` em produção.
- Para produção, prefira `SinkSeq` ou um sink customizado que envie para seu backend de observabilidade.