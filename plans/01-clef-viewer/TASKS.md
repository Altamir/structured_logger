# CLEF Viewer — Tasks

Última atualização: 2026-06-26 (pós `42d126d` — SSE validado em produção)

Legenda: ✅ concluído · 🔄 em progresso · ⏳ pendente · 🚫 cancelado

---

## Fase 1 — MVP (requisitos R1–R6)

| ID | Task | Status | Evidência |
|----|------|--------|-----------|
| T01 | Aprovar requisitos EARS | ✅ | [clef-viewer-requirements.md](clef-viewer-requirements.md) |
| T02 | Design técnico | ✅ | [clef-viewer-design.md](clef-viewer-design.md) |
| T03 | Scaffold `server/` + `ui/` | ✅ | `apps/clef_viewer/` |
| T04 | Ingest CLEF (`/api/events/raw?clef`, `/ingest/clef`) | ✅ | `ingest_handler.dart`, testes integração |
| T05 | SQLite + rotação FIFO | ✅ | `log_repository.dart`, `schema.dart` |
| T06 | Query + filtros API | ✅ | `query_handler.dart`, `log_filter.dart` |
| T07 | Agrupamentos API | ✅ | `group_handler.dart` |
| T08 | SSE server (`/api/events/stream`) | ✅ | `sse_handler.dart`, `event_broadcaster.dart` |
| T09 | UI Viewer (tabela, filtros, grupos, pause) | ✅ | `viewer_page.dart`, widgets |
| T10 | UI Admin (delete, export, API key) | ✅ | `admin_page.dart` |
| T11 | Testes server (50) | ✅ | `dart test` em `server/` (incl. SSE shelf_io TCP) |
| T12 | Testes UI (4) | ✅ | `flutter test` em `ui/` |
| T13 | README + quick start | ✅ | `apps/clef_viewer/README.md` |

---

## Fase 2 — Deploy Docker / VPS

| ID | Task | Status | Evidência |
|----|------|--------|-----------|
| T20 | Dockerfiles server + webapp | ✅ | `server/Dockerfile`, `ui/Dockerfile` |
| T21 | nginx proxy same-origin (`/api`, `/ingest`) | ✅ | `ui/nginx.conf` |
| T22 | Compose produção (imagens públicas GHCR) | ✅ | `docker-compose.yml` |
| T23 | Compose build local + dev overlay | ✅ | `docker-compose.build.yml`, `docker-compose.dev.yml` |
| T24 | CI publicação imagens | ✅ | `.github/workflows/clef-viewer-images.yml` |
| T25 | Labels Traefik (UI + ingest) | ✅ | `docker-compose.yml` |
| T26 | Deploy Hostinger Docker Manager | ✅ | VPS em produção |
| T27 | Pacotes GHCR públicos | ⏳ | Verificar visibilidade em GitHub → Packages |
| T28 | Checklist aceitação EARS manual | 🔄 | SSE + versão OK; demais itens abaixo |

---

## Fase 3 — Correções pós-deploy

| ID | Task | Status | Notas |
|----|------|--------|-------|
| T30 | Build web CI (`--web-renderer` removido Flutter 3.38) | ✅ | `adc1abc` |
| T31 | `SinkSeq` redirect HTTP→HTTPS (Traefik 301) | ✅ | `95cea6c` — preferir `https://` na URL |
| T32 | SSE tempo real (Flutter Web + shelf_io) | ✅ | `42d126d` — `shelf.io.buffer_output: false`; validado na VPS |
| T36 | Fallback polling 3s na UI | ✅ | `viewer_page.dart` — backup se proxy bloquear SSE |
| T33 | Remover dependência Flutter do `SinkSeq` | ✅ | `_kDebugMode` sem `package:flutter` |
| T34 | Constantes CLEF locais no server (build Docker) | ✅ | `server/lib/clef/seq_constants.dart` |
| T35 | Barra de versão na UI (webapp + server) | ✅ | `c74a8d2` — `VersionBar` + `/health.version` |

---

## Aceitação manual

Checklist rápido pós-deploy (operador):

- [x] `curl https://<ingest-host>/health` → 200
- [x] `curl https://<ui-host>/health` → 200 (via nginx)
- [x] Barra de versão: `webapp XXXXXXX · server XXXXXXX` (prefixos **iguais**)
- [x] `curl -N https://<ui-host>/api/events/stream` retorna `: connected` imediatamente
- [x] `SinkSeq` com `https://<ingest-host>` + `INGEST_API_KEY` → log na UI **sem** Apply
- [x] Filtros Apply/Clear funcionam
- [x] Agrupamento por level + clique aplica filtro
- [x] Admin: export NDJSON e delete com confirmação
- [ ] Pause/Resume interrompe e retoma SSE
- [x] Volume `clef_data` persiste após restart dos containers

---

## Próximas tasks (backlog)

| ID | Task | Prioridade |
|----|------|------------|
| T40 | Publicar `structured_logger` com fix `SinkSeq` redirect | Média |
| T41 | Atualizar contagem de grupos em tempo real (SSE) | Baixa |
| T42 | Migrar `dart:html` → `package:web` (deprecation) | Baixa |
| T43 | Pin de imagem por SHA no compose (opcional) | Baixa — versão já visível na UI |
| T44 | Documentar variáveis no painel Hostinger (screenshot) | Baixa |