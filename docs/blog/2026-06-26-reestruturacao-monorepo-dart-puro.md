---
slug: reestruturacao-monorepo-dart-puro
title: Reestruturação do structured_logger para monorepo Dart-puro
authors: [altamir]
tags: [dart, monorepo, melos, release]
date: 2026-06-26T10:00:00
---

Com o crescimento do ecossistema, decidimos reestruturar o pacote `structured_logger` para suportar melhor o uso em Dart puro (CLI, servidores) sem depender do Flutter.

## Visão geral da reestruturação

O principal objetivo foi separar o **core** do pacote do ecossistema Flutter, permitindo que ele seja usado diretamente em projetos Dart puros.

```mermaid
flowchart TB
    subgraph Antes
        A1[Root Flutter package]
        A2[lib/ + test/ + example/]
        A3[Depende de flutter]
    end

    subgraph Depois
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

## O que mudou

### 1. Monorepo com Pub Workspaces + Melos 8

- Raiz agora é **meta-only** (apenas configuração de workspace)
- Pacotes em `packages/`
- Aplicações em `apps/`

```mermaid
flowchart LR
    Root[Root<br/>pubspec.yaml + melos]
    subgraph packages["packages/"]
        Core[structured_logger<br/>Dart puro v1.0.0]
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

### 2. Core agora é Dart-puro (v1.0.0)

- Removida dependência de `flutter`
- SDK mínimo: `^3.6.0`
- `resolution: workspace` em todos os membros
- API pública **100% compatível**

### 3. Novo pacote de integração

```mermaid
sequenceDiagram
    participant App as Aplicação
    participant Logger as StructureLogger
    participant Interceptor as DioLoggingInterceptor
    participant Sink as SinkSeq

    App->>Logger: addSink(SinkSeq(...))
    App->>App: Dio().interceptors.add(DioLoggingInterceptor(logger))
    App->>Interceptor: onRequest / onResponse / onError
    Interceptor->>Logger: log(event)
    Logger->>Sink: emit CLEF
```

### 4. Integração com CLEF Viewer

O server agora depende diretamente do pacote via workspace:

```mermaid
flowchart LR
    Core[structured_logger] --> Server[clef_viewer_server]
    Server -->|import| Core
```

Eliminamos a cópia manual de `seq_constants.dart`.

### 5. CI mais inteligente

```mermaid
flowchart TD
    Start[Push / PR] --> Test[Test + Analyze<br/>melos run ci]
    Test -->|sucesso| IsPR{É PR?}

    IsPR -->|Sim| PRTags[Imagens: run_number-DEV-PR]
    IsPR -->|Não| MainTags[Imagens: run_number + latest + sha]

    Test -->|sucesso| Docs[Docs deploy]
    Docs -->|PR| DocsPR[Branch: pr-123<br/>Preview separada]
    Docs -->|Main| DocsMain[Branch: master<br/>Produção + latest]

    PRTags -->|push| GHCR[GHCR]
    MainTags -->|push| GHCR
```

## Por que isso importa

- Uso em **Dart puro** sem Flutter SDK
- Manutenção centralizada no monorepo
- Previews automáticas de imagens e docs em PRs
- `latest` sempre reflete a última versão estável da main

## Próximos passos

- Publicação oficial de `structured_logger` 1.0.0
- Publicação do `structured_logger_dio_interceptor`
- Guia completo de migração

---

Obrigado a todos que testaram as versões anteriores. Feedback é bem-vindo!

<!--truncate-->
