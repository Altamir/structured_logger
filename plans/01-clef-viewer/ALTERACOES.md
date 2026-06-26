# CLEF Viewer — Alterações do plano

Registro de desvios e decisões tomadas durante a implementação em relação aos documentos originais de requisitos e design.

---

## 2026-06-26 — Deploy VPS (Hostinger)

### O que mudou

| Plano original | Implementado | Motivo |
|----------------|--------------|--------|
| Docker Compose local com `build:` | `docker-compose.yml` só com imagens públicas GHCR | VPS (Hostinger Docker Manager) não faz build — apenas `docker compose up` |
| Serviços `server` + `ui` | Serviços `server` + `webapp` | Nomenclatura alinhada ao pedido do painel Hostinger |
| Deploy via scripts `.sh` | Compose autossuficiente + env no painel | VPS autogerencia compose; scripts ficaram opcionais para dev local |
| Traefik em arquivo overlay separado | Labels Traefik no `docker-compose.yml` principal | Um único YAML para colar ou URL raw no GitHub |
| Fora de escopo: deploy cloud | Deploy VPS documentado | Escopo ampliado a pedido do stakeholder |

### Artefatos novos

- `.github/workflows/clef-viewer-images.yml` — CI build/push GHCR
- `docker-compose.build.yml` — build local a partir do código
- `docker-compose.dev.yml` — portas públicas, Traefik off
- `docker-compose.prebuilt.yml` — UI pré-buildada com Flutter local

### URLs de deploy

- Compose: `https://raw.githubusercontent.com/Altamir/structured_logger/master/apps/clef_viewer/docker-compose.yml`
- Imagens: `ghcr.io/altamir/clef-viewer-server`, `ghcr.io/altamir/clef-viewer-webapp`

---

## 2026-06-26 — Correções produção

### SinkSeq + Traefik (HTTP 301)

- **Sintoma:** `Error sending logs to Seq: Permanent Redirect`
- **Causa:** Traefik redireciona `http://` → `https://`; `http` package não segue POST em 301
- **Correção:** `SinkSeq` repete POST no `Location`; apps devem preferir `https://` na URL de ingest

### CI Docker webapp (exit 64)

- **Causa:** flag `--web-renderer html` removida no Flutter 3.38+
- **Correção:** `flutter build web --release --no-wasm-dry-run`

### SSE não atualiza UI em tempo real (VPS)

- **Causa:** `SseClient` usava streaming `http.Client` — não funciona no Flutter Web
- **Correção:** `sse_client_web.dart` com `EventSource` + export condicional
- **Status:** implementado no código; **pendente redeploy** da imagem `clef-viewer-webapp`

---

## 2026-06-26 — Decisões técnicas (MVP)

### Server sem dependência de `structured_logger`

- **Plano:** reutilizar `seq_constants.dart` do pacote
- **Implementado:** cópia local em `server/lib/clef/seq_constants.dart`
- **Motivo:** build Docker do server sem Flutter SDK (`dart pub get` falhava)

### UI API same-origin

- **Plano:** `CLEF_VIEWER_API` opcional em dev
- **Implementado:** build Docker com `CLEF_VIEWER_API=` vazio → URIs relativas; nginx faz proxy para `server:5341`

### `SinkSeq` sem Flutter

- **Plano:** pacote com `flutter` SDK
- **Implementado:** `_kDebugMode` via `bool.fromEnvironment('dart.vm.product')` — example virou CLI puro

---

## Impacto nos requisitos

| Req | Impacto |
|-----|---------|
| R3 — Tempo real | Critério 3 dependia de SSE no browser; corrigido com `EventSource` (T32) |
| NFR — Portabilidade | Mantido para `dart run`; produção via containers |
| Out of scope — cloud | **Removido** do out-of-scope; deploy VPS entrou no escopo entregue |

---

## Commits relevantes (master)

| Commit | Descrição |
|--------|-----------|
| `08ff662` | feat(clef-viewer): app completo + compose + CI |
| `adc1abc` | fix(clef-viewer): build web Docker CI |
| `95cea6c` | fix(sink-seq): redirect http→https no POST |
| _(local)_ | fix(ui): SSE EventSource para Flutter Web — aguarda commit |