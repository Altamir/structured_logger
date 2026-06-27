---
slug: restructuring-monorepo-dart-pure
title: Restructuring structured_logger to a Dart-pure monorepo
authors: [altamir]
tags: [dart, monorepo, melos, release]
date: 2026-06-26T10:00:00
---

With the growth of the ecosystem, we decided to restructure the `structured_logger` package to better support pure Dart usage (CLI, servers) without depending on Flutter.

## Overview of the restructuring

The main goal was to separate the **core** of the package from the Flutter ecosystem, allowing it to be used directly in pure Dart projects.

```mermaid
flowchart TB
    subgraph Before
        A1[Root Flutter package]
        A2[lib/ + test/ + example/]
        A3[Depends on flutter]
    end

    subgraph After
        B1[Root monorepo]
        B2[packages/structured_logger v1.0.0]
        B3[packages/structured_logger_dio_interceptor v0.1.0]
        B4[apps/clef_viewer/server]
        B5[apps/clef_viewer/ui]

        B1 --> B2
        B1 --> B3
        B1 --> B4
        B1 --> B5

        B2 -.->|dep workspace| B3
        B2 -.->|dep workspace| B4
    end

    A1 --> B1
```

## What changed

### 1. Monorepo with Pub Workspaces + Melos 8

- The root is now **meta-only** (just workspace configuration)
- Packages live in `packages/`
- Applications live in `apps/`

```mermaid
flowchart LR
    Root[Root<br/>pubspec.yaml + melos]
    subgraph packages["packages/"]
        Core[structured_logger<br/>Pure Dart v1.0.0]
        Interceptor[structured_logger_dio_interceptor<br/>v0.1.0]
    end
    subgraph apps["apps/clef_viewer/"]
        Server[server<br/>Dart]
        UI[ui<br/>Flutter Web]
    end

    Root --> packages
    Root --> apps
    Core -->|workspace: true| Interceptor
    Core -->|workspace: true| Server
```

### 2. Core is now pure Dart (v1.0.0)

- Removed the `flutter` dependency
- Minimum SDK: `^3.6.0`
- `resolution: workspace` on all members
- Public API **100% compatible**

### 3. New integration package

```mermaid
sequenceDiagram
    participant App as Application
    participant Logger as StructureLogger
    participant Interceptor as DioLoggingInterceptor
    participant Sink as SinkSeq

    App->>Logger: addSink(SinkSeq(...))
    App->>App: Dio().interceptors.add(DioLoggingInterceptor(logger))
    App->>Interceptor: onRequest / onResponse / onError
    Interceptor->>Logger: log(event)
    Logger->>Sink: emit CLEF
```

### 4. Integration with CLEF Viewer

The server now depends directly on the core package via workspace:

```mermaid
flowchart LR
    Core[structured_logger] --> Server[clef_viewer_server]
    Server -->|import| Core
```

We eliminated the manual copy of `seq_constants.dart`.

### 5. Smarter CI

```mermaid
flowchart TD
    Start[Push / PR] --> Test[Test + Analyze<br/>melos run ci]
    Test -->|success| IsPR{Is PR?}

    IsPR -->|Yes| PRTags[Images: run_number-DEV-PR]
    IsPR -->|No| MainTags[Images: run_number + latest + sha]

    Test -->|success| Docs[Docs deploy]
    Docs -->|PR| DocsPR[Branch: pr-123<br/>Separate preview]
    Docs -->|Main| DocsMain[Branch: master<br/>Production + latest]

    PRTags -->|push| GHCR[GHCR]
    MainTags -->|push| GHCR
```

## Why this matters

- Use in **pure Dart** without the Flutter SDK
- Centralized maintenance in the monorepo
- Automatic previews of images and docs on PRs
- `latest` always reflects the latest stable version from main

## Next steps

- Official release of `structured_logger` 1.0.0
- Release of `structured_logger_dio_interceptor`
- Complete migration guide

---

Thanks to everyone who tested the previous versions. Feedback is always welcome!