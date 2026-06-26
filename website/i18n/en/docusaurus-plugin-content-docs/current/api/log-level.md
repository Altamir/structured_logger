---
sidebar_position: 4
title: LogLevel
description: Severity level enum for log events.
---

# LogLevel

Enum with severity levels used in `StructureLogger.log()`.

## Values

| Value | `sValue` | Use |
|-------|----------|-----|
| `LogLevel.info` | `"info"` | Normal flow events |
| `LogLevel.warning` | `"warning"` | Potentially problematic situations |
| `LogLevel.debug` | `"debug"` | Detailed diagnostics |
| `LogLevel.error` | `"error"` | Errors that may allow the app to continue |
| `LogLevel.verbose` | `"verbose"` | Fine trace, more detailed than `debug` |

## `LogLevelExtension`

```dart
extension LogLevelExtension on LogLevel {
  String get sValue;
}
```

Converts the enum to the string stored in `LogModel.level` and serialized as `@l` in CLEF.

## Example

```dart
await logger.log('Done', level: LogLevel.info);
// LogModel.level == "info"
```