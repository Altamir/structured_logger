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

### Variáveis no painel Hostinger

**Obrigatórias** (sem mudança desde o deploy inicial):

- `ADMIN_API_KEY`, `INGEST_API_KEY`
- `CLEF_UI_HOST`, `CLEF_INGEST_HOST`
- `CLEF_VIEWER_PORT_MAPPING`, `CLEF_VIEWER_UI_PORT_MAPPING`

**Não obrigatórias** para versão ou SSE — `CLEF_VIEWER_VERSION` é injetada no build da imagem pelo CI (`github.sha`).

---

## 2026-06-26 — Correções produção

### SinkSeq + Traefik (HTTP 301)

- **Sintoma:** `Error sending logs to Seq: Permanent Redirect`
- **Causa:** Traefik redireciona `http://` → `https://`; `http` package não segue POST em 301
- **Correção:** `SinkSeq` repete POST no `Location` (`95cea6c`); apps devem usar `https://` na URL de ingest

### CI Docker webapp (exit 64)

- **Causa:** flag `--web-renderer html` removida no Flutter 3.38+
- **Correção:** `flutter build web --release --no-wasm-dry-run` (`adc1abc`)

### SSE não atualiza UI em tempo real (VPS)

Iteração 1 (`fb58f95`):

- **Causa:** `SseClient` usava streaming `http.Client` — não funciona no Flutter Web
- **Correção:** `sse_client_web.dart` com `EventSource` + export condicional

Iteração 2 (`d1d5257`):

- **Causa adicional:** `addEventListener('log')` pouco confiável; buffering nginx/Traefik; `ApiConfig` podia apontar para `localhost` no build
- **Correções:**
  - Servidor envia SSE como mensagem padrão (`data:` sem `event: log`); heartbeat em comentário `: heartbeat`
  - Cliente usa `EventSource.onMessage` + URL absoluta (`window.location.origin`)
  - nginx: `gzip off`, `X-Accel-Buffering no` em `/api/events/stream`
  - Headers anti-buffer no `sse_handler.dart`

Iteração 3 (`42d126d`) — **causa raiz**:

- **Sintoma:** `curl -N /api/events/stream` retornava HTTP 200 mas **0 bytes** (local e VPS)
- **Causa:** `shelf_io` bufferiza corpos chunked por padrão (`HttpResponse.bufferOutput = true`); o stream SSE nunca era enviado ao socket
- **Correção:** `context: {'shelf.io.buffer_output': false}` na `Response` do `SseHandler`
- **Complementos:**
  - Testes TCP reais com `shelf_io` (`sse_shelf_io_test.dart`, `sse_async_star_test.dart`)
  - Fallback na UI: polling silencioso a cada 3s (`viewer_page.dart`) se proxy bloquear SSE
  - nginx: `proxy_request_buffering off`, `add_header ... always`
  - Traefik: `loadbalancer.responseForwarding.flushInterval=1ms` no router da UI

- **Status:** **validado em produção** (`clef.altamir.dev`) — logs aparecem em tempo real sem Apply

### Versão visível na UI (`c74a8d2`)

- Barra abaixo do AppBar: `webapp abc1234 · server abc1234`
- **webapp:** `--dart-define=CLEF_VIEWER_VERSION` no build Flutter (CI passa `github.sha`)
- **server:** `GET /health` → campo `version` (`ENV` na imagem Docker)
- Prefixos iguais confirmam que ambos os containers foram atualizados juntos

---

## 2026-06-26 — Decisões técnicas (MVP)

### Server sem dependência de `structured_logger`

- **Plano:** reutilizar `seq_constants.dart` do pacote
- **Implementado:** cópia local em `server/lib/clef/seq_constants.dart`
- **Motivo:** build Docker do server sem Flutter SDK

### UI API same-origin

- Build Docker com `CLEF_VIEWER_API=` vazio → URIs relativas; nginx faz proxy para `server:5341`

### `SinkSeq` sem Flutter

- `_kDebugMode` via `bool.fromEnvironment('dart.vm.product')` — example virou CLI puro

---

## Impacto nos requisitos

| Req | Impacto |
|-----|---------|
| R3 — Tempo real | SSE: `buffer_output: false` no shelf_io + `EventSource.onMessage`; validado na VPS |
| NFR — Observabilidade | Versão de deploy visível na UI e em `/health` |
| Out of scope — cloud | **Removido** do out-of-scope; deploy VPS entrou no escopo entregue |

---

## Commits relevantes (master)

| Commit | Descrição |
|--------|-----------|
| `08ff662` | feat(clef-viewer): app completo + compose + CI |
| `adc1abc` | fix(clef-viewer): build web Docker CI |
| `95cea6c` | fix(sink-seq): redirect http→https no POST |
| `fb58f95` | fix(clef-viewer): SSE EventSource no Flutter Web |
| `d1d5257` | fix(clef-viewer): SSE produção (onMessage, nginx, servidor) |
| `c74a8d2` | feat(clef-viewer): versão webapp/server na UI |
| `42d126d` | fix(clef-viewer): SSE realtime (`shelf.io.buffer_output`) |