---
sidebar_position: 1
slug: /
title: Introduction
description: Structured logging package for Flutter with pluggable sinks.
---

# structured_logger

**structured_logger** is a Flutter package for structured logging. Instead of plain strings, you emit events with a **level**, **message template**, and **properties** — and route each event to one or more pluggable **sinks**.

## Why structured logging?

Structured logs make search, filtering, and correlation easier in production:

- **Templates** with placeholders (`{userId}`, `{duration}`) keep messages readable while data stays queryable.
- **Levels** (`info`, `warning`, `error`, …) help filter noise.
- **Sinks** decouple emission from destination: console, `dart:developer`, [Seq](https://datalust.co/seq), or any backend you implement.

## Key features

| Feature | Description |
|---------|-------------|
| `StructureLogger` | Central logger that fans out events to all registered sinks |
| `LogSink` | Interface for output destinations |
| `SimpleLineSink` | Human-readable terminal line with placeholder interpolation |
| `DefaultSink` | Output to the Dart developer log (`dart:developer`) |
| `SinkSeq` | CLEF delivery to Seq servers |
| `LogModel` | Event model with CLEF-compatible fields (`@t`, `@mt`, `@l`) |

## Requirements

- Dart SDK `>=3.1.5 <4.0.0`
- Flutter `>=1.17.0`

## Next steps

- [Installation](./getting-started/installation) — add the package to your `pubspec.yaml`
- [Quick start](./getting-started/quick-start) — your first log in minutes
- [Architecture](./concepts/architecture) — how logger, model, and sinks relate
- [Seq integration](./guides/seq-integration) — send logs to a Seq server