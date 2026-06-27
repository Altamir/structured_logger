---
slug: reestruturacao-monorepo-dart-puro
title: Reestruturação do structured_logger para monorepo Dart-puro
authors: [altamir]
tags: [dart, monorepo, melos, release]
date: 2026-06-26T10:00:00
---

Com o crescimento do ecossistema, decidimos reestruturar o pacote `structured_logger` para suportar melhor o uso em Dart puro (CLI, servidores) sem depender do Flutter.

## O que mudou

- **Monorepo com Pub Workspaces + Melos 8**: raiz meta-only, pacotes em `packages/`, apps em `apps/`.
- **Core Dart-puro v1.0.0**: `packages/structured_logger` agora é puro Dart (`^3.6.0`), sem `flutter` no pubspec. API pública inalterada.
- **Novo pacote de integração**: `structured_logger_dio_interceptor` (v0.1.0) — interceptor que usa um `StructureLogger` já configurado com sinks.
- **Integração com CLEF Viewer**: server agora depende diretamente do core via workspace (sem cópia de constantes).
- **CI mais inteligente**: testes rodam primeiro; imagens e docs só são construídas em main/master (com `latest`); em PRs geramos tags `DEV-PR` para previews.

## Por que isso importa

Agora é possível usar o logger em projetos Dart puros sem instalar o Flutter SDK. O monorepo facilita manutenção, releases coordenadas e previews de docs/imagens durante revisão de PRs.

## Próximos passos

- Publicação oficial de `structured_logger` 1.0.0 e do interceptor.
- Migração de consumidores existentes (guia disponível nos docs).
- Mais sinks e integrações no roadmap.

Obrigado a todos que testaram as versões anteriores. Feedback é bem-vindo!

<!--truncate-->
