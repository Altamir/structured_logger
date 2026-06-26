---
sidebar_position: 3
title: Message templates
description: How to use placeholders and structured properties in logs.
---

# Message templates

The `message` parameter of `StructureLogger.log()` is a **message template**: text with `{name}` placeholders filled from `data`.

## Syntax

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

- The template is stored in `LogModel.mt` (`@mt` in CLEF).
- Properties live in `LogModel.data`, separate from the rendered message.
- Tools like Seq index `data` for search and dashboards.

## Interpolation in SimpleLineSink

`SimpleLineSink` uses the regex `\{(.*?)\}` to replace each placeholder with the corresponding value in `data`:

```dart
// Template: "Hello {name}"
// data: {name: "Ana"}
// Result: "Hello Ana"
```

Values are converted with `.toString()`. Missing keys produce an empty substitution.

## Best practices

1. **Use descriptive names** — `{userId}` instead of `{id}` when ambiguous.
2. **Keep templates stable** — easier grouping and alerts in structured backends.
3. **Put variable data in `data`** — avoid manual string concatenation in the template.
4. **Avoid sensitive data** — passwords and tokens should not appear in `data` if logs are exported.

## CLEF compatibility

The model follows Serilog/CLEF conventions:

```json
{
  "@t": "2026-06-25T10:00:00.000",
  "@mt": "Payment {status} for order {orderId}",
  "@l": "info",
  "status": "approved",
  "orderId": "ORD-991"
}
```

In `SinkSeq`, `data` properties are merged into the CLEF event while `@t`, `@mt`, `@l`, and `DeviceIdentifier` are reserved and cannot be accidentally overwritten by keys in `data`.