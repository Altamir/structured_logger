# CLEF Viewer — Tasks

Última atualização: 2026-06-26

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
| T11 | Testes server (47) | ✅ | `dart test` em `server/` |
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
| T28 | Checklist aceitação EARS manual | ⏳ | Ver [TASKS.md#aceitação-manual](#aceitação-manual) |

---

## Fase 3 — Correções pós-deploy

| ID | Task | Status | Notas |
|----|------|--------|-------|
| T30 | Build web CI (`--web-renderer` removido Flutter 3.38) | ✅ | commit `adc1abc` |
| T31 | `SinkSeq` redirect HTTP→HTTPS (Traefik 301) | ✅ | commit `95cea6c` — usar `https://` ou atualizar pacote |
| T32 | SSE tempo real no Flutter Web (`EventSource`) | 🔄 | código pronto; **aguarda rebuild webapp na VPS** |
| T33 | Remover dependência Flutter do `SinkSeq` | ✅ | `_kDebugMode` sem `package:flutter` |
| T34 | Constantes CLEF locais no server (build Docker) | ✅ | `server/lib/clef/seq_constants.dart` |

---

## Aceitação manual

Checklist rápido pós-deploy (operador):

- [ ] `curl https://<ingest-host>/health` → 200
- [ ] `curl https://<ui-host>/health` → 200 (via nginx)
- [ ] `SinkSeq` com `https://<ingest-host>` + `INGEST_API_KEY` → log aparece na UI **sem** clicar Apply
- [ ] Filtros Apply/Clear funcionam
- [ ] Agrupamento por level + clique aplica filtro
- [ ] Admin: export NDJSON e delete com confirmação
- [ ] Pause/Resume interrompe e retoma SSE
- [ ] Volume `clef_data` persiste após restart dos containers

---

## Próximas tasks (backlog)

| ID | Task | Prioridade |
|----|------|------------|
| T40 | Publicar `structured_logger` com fix `SinkSeq` redirect | Média |
| T41 | Atualizar contagem de grupos em tempo real (SSE) | Baixa |
| T42 | Migrar `dart:html` → `package:web` (deprecation) | Baixa |
| T43 | Tag/versionar imagens GHCR (não só `:latest`) | Baixa |
| T44 | Documentar variáveis no painel Hostinger (screenshot) | Baixa |