# Monorepo Melos com core Dart-first

O repositório `structured_logger` migra de pacote Flutter na raiz para monorepo com `packages/structured_logger` (Dart puro, v1.0.0), integrações em `packages/`, apps em `apps/`, orquestrado por Pub Workspaces + Melos 7.8.x. Flutter permanece consumidor, não dependência do core.

**Considered:** core na raiz com path deps manuais; só pub workspaces sem Melos; pacote único Flutter.

**Consequences:** Dockerfile do CLEF Viewer server passa a copiar `packages/structured_logger` no build context; releases usam `melos version` por pacote; `dio_interceptor_seq` é substituído por `structured_logger_dio_interceptor`.