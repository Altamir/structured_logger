---
sidebar_position: 3
title: LogModel
description: Log event model with CLEF-compatible fields.
---

# LogModel

Represents a structured log event passed to sinks.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `t` | `String` | ISO-8601 timestamp (`@t` in CLEF) |
| `mt` | `String` | Message template (`@mt`) |
| `level` | `String` | Level name (`@l`) |
| `data` | `Map<String, dynamic>?` | Structured properties |

## Constructor

```dart
LogModel({
  required String mt,
  String level = "debug",
  Map<String, dynamic>? data,
  String t = "",
})
```

If `t` is empty, the current timestamp (`DateTime.now().toIso8601String()`) is assigned automatically.

## Serialization

### `toMap()`

```dart
Map<String, dynamic> toMap()
```

Returns:

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

Rebuilds a `LogModel` from a map produced by `toMap()`.