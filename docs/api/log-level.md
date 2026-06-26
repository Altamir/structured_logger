---
sidebar_position: 4
title: LogLevel
description: Enum de níveis de severidade para eventos de log.
---

# LogLevel

Enum com os níveis de severidade usados em `StructureLogger.log()`.

## Valores

| Valor | `sValue` | Uso |
|-------|----------|-----|
| `LogLevel.info` | `"info"` | Eventos informativos do fluxo normal |
| `LogLevel.warning` | `"warning"` | Situações potencialmente problemáticas |
| `LogLevel.debug` | `"debug"` | Diagnóstico detalhado |
| `LogLevel.error` | `"error"` | Erros que podem permitir continuidade |
| `LogLevel.verbose` | `"verbose"` | Traço fino, mais detalhado que `debug` |

## Extensão `LogLevelExtension`

```dart
extension LogLevelExtension on LogLevel {
  String get sValue;
}
```

Converte o enum para a string armazenada em `LogModel.level` e serializada como `@l` no CLEF.

## Exemplo

```dart
await logger.log('Done', level: LogLevel.info);
// LogModel.level == "info"
```