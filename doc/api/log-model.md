---
sidebar_position: 3
title: LogModel
description: Modelo de evento de log com campos compatíveis com CLEF.
---

# LogModel

Representa um evento de log estruturado passado aos sinks.

## Propriedades

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `t` | `String` | Timestamp ISO-8601 (`@t` no CLEF) |
| `mt` | `String` | Message template (`@mt`) |
| `level` | `String` | Nome do nível (`@l`) |
| `data` | `Map<String, dynamic>?` | Propriedades estruturadas |

## Construtor

```dart
LogModel({
  required String mt,
  String level = "debug",
  Map<String, dynamic>? data,
  String t = "",
})
```

Se `t` for vazio, o timestamp atual (`DateTime.now().toIso8601String()`) é atribuído automaticamente.

## Serialização

### `toMap()`

```dart
Map<String, dynamic> toMap()
```

Retorna:

```dart
{
  '@t': t,
  '@mt': mt,
  '@l': level,
  'data': data,
}
```

### `fromMap`

```dart
factory LogModel.fromMap(Map<String, dynamic> map)
```

Reconstrói um `LogModel` a partir de um mapa produzido por `toMap()`.