# CLEF Viewer

Local webapp that receives CLEF events (Seq-compatible) and provides a Flutter Web UI for realtime viewing, filtering, grouping, and admin operations.

## Quick Start

### 1. Start the server

```bash
cd apps/clef_viewer/server
dart pub get
DEV_MODE=true dart run bin/server.dart   # local dev without ADMIN_API_KEY
# Or set ADMIN_API_KEY for protected admin routes:
# ADMIN_API_KEY=your-secret dart run bin/server.dart
```

Server listens on **http://localhost:5341** by default.

Optional environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `5341` | HTTP port |
| `DB_PATH` | `./clef_viewer.db` | SQLite file path |
| `INGEST_API_KEY` | _(unset)_ | Protects ingest routes when set |
| `ADMIN_API_KEY` | _(unset)_ | Protects `/api/admin/*` when set |
| `MAX_ROWS` | `100000` | FIFO rotation limit |
| `STATIC_PATH` | `../ui/build/web` | Flutter Web build output |
| `DEV_MODE` | `false` | Set `true` to allow startup without `ADMIN_API_KEY` |
| `MAX_BATCH_EVENTS` | `1000` | Max events per NDJSON batch |
| `MAX_BATCH_BYTES` | `10485760` | Max bytes per NDJSON batch |

### 2. Run the UI (development)

```bash
cd apps/clef_viewer/ui
flutter pub get
flutter run -d chrome --web-port 8080
```

The UI defaults to `http://localhost:5341` for API calls. Override with:

```bash
flutter run -d chrome --dart-define=CLEF_VIEWER_API=http://localhost:5341
```

### 3. Production (single server)

```bash
cd apps/clef_viewer/ui && flutter build web
cd ../server && ADMIN_API_KEY=your-production-secret dart run bin/server.dart
```

The server serves API + static assets from `ui/build/web`.

**Important:** Production startup requires `ADMIN_API_KEY`. Do **not** use `DEV_MODE=true` in production — that flag is only for local development without an admin key.

## Point SinkSeq to CLEF Viewer

No code changes to `structured_logger` are required — only the URL:

```dart
import 'package:structured_logger/structured_logger.dart';

final sink = SinkSeq(
  'http://localhost:5341',
  apiKey: Platform.environment['CLEF_VIEWER_INGEST_KEY'], // if INGEST_API_KEY set
  deviceIdentifier: 'my-app-dev',
);
```

`SinkSeq` posts to `/api/events/raw?clef` with `Content-Type: application/vnd.serilog.clef`.

## API Overview

| Endpoint | Description |
|----------|-------------|
| `POST /api/events/raw?clef` | Seq-compatible single-event ingest |
| `POST /ingest/clef` | Single JSON or NDJSON batch ingest |
| `GET /api/events` | Query with filters |
| `GET /api/events/group` | Group by level/time/device/property (`group_property` names the JSON key when `group_by=property`) |
| `GET /api/events/stream` | SSE realtime stream |
| `DELETE /api/admin/logs` | Delete all or filtered (requires admin key) |
| `GET /api/admin/export` | NDJSON CLEF export |
| `GET /health` | Health check |

Admin routes use header `X-Seq-ApiKey` matching `ADMIN_API_KEY`.

## Docker Compose

Dois serviços:

| Serviço | Imagem pública | Função |
|---------|----------------|--------|
| `server` | `ghcr.io/altamir/clef-viewer-server:latest` | API + ingest SinkSeq (porta 5341) |
| `webapp` | `ghcr.io/altamir/clef-viewer-webapp:latest` | Flutter Web + nginx (porta 80) |

O **webapp** faz proxy de `/api`, `/ingest` e `/health` para `http://server:5341` na rede interna do Compose — não precisa configurar URL da API.

Imagens publicadas automaticamente pelo CI (`.github/workflows/clef-viewer-images.yml`) a cada push em `apps/clef_viewer/`. Na primeira publicação, torne os pacotes **Public** em GitHub → Packages.

### Dev local (build a partir do código)

```bash
cd apps/clef_viewer
cp .env.example .env
# Edite .env — ADMIN_API_KEY; hosts localhost; portas públicas (veja .env.example)

docker compose -f docker-compose.yml -f docker-compose.build.yml -f docker-compose.dev.yml up --build
```

**Opcional:** `./scripts/docker-up.sh` — idem, com build Flutter local quando disponível (mais rápido).

### Troubleshooting Docker

**`docker-credential-desktop: executable file not found`**

Docker is configured with `"credsStore": "desktop"` but the credential helper is not on `PATH`. Fixes:

```bash
# macOS — add Docker Desktop helpers to PATH for this shell:
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker compose up --build
```

Or edit `~/.docker/config.json` and remove the `"credsStore": "desktop"` line (Docker will pull public images without the helper).

**Skip in-Docker Flutter build** (if the UI image build is slow or fails):

```bash
cd apps/clef_viewer/ui
flutter build web --release --dart-define=CLEF_VIEWER_API=
cd ..
docker compose -f docker-compose.yml -f docker-compose.build.yml -f docker-compose.prebuilt.yml up --build
```

| URL | Purpose |
|-----|---------|
| http://localhost:8080 | Web UI |
| http://localhost:5341 | API / SinkSeq ingest (direct) |

Point `SinkSeq` at the **server** port (logs do not go through nginx):

```dart
SinkSeq('http://localhost:5341', apiKey: '...', deviceIdentifier: 'my-app')
```

Environment variables (`.env`):

| Variable | Default | Description |
|----------|---------|-------------|
| `ADMIN_API_KEY` | _(required)_ | Admin API protection |
| `INGEST_API_KEY` | _(unset)_ | Optional ingest protection |
| `CLEF_VIEWER_SERVER_IMAGE` | `ghcr.io/altamir/clef-viewer-server:latest` | Imagem do server |
| `CLEF_VIEWER_WEBAPP_IMAGE` | `ghcr.io/altamir/clef-viewer-webapp:latest` | Imagem do webapp |
| `CLEF_UI_HOST` | `localhost` | Domínio da UI (Traefik) |
| `CLEF_INGEST_HOST` | `localhost` | Domínio do ingest (Traefik) |
| `TRAEFIK_ENTRYPOINT` | `websecure` | Entrypoint Traefik |
| `TRAEFIK_CERT_RESOLVER` | `letsencrypt` | Cert resolver Traefik |
| `CLEF_VIEWER_PORT_MAPPING` | `127.0.0.1:5341:5341` | Host:container for API/ingest |
| `CLEF_VIEWER_UI_PORT_MAPPING` | `127.0.0.1:8080:80` | Host:container for webapp |

SQLite data is persisted in the `clef_data` Docker volume.

```bash
docker compose down          # stop
docker compose down -v       # stop and delete logs volume
```

## Deploy na Hostinger (Docker Manager)

O `docker-compose.yml` usa **somente imagens públicas** — a VPS só faz `pull`, sem build.

### 1. Publicar imagens (uma vez)

Faça push em `master` (ou merge via PR aprovado de develop → master) com mudanças em `apps/clef_viewer/`. Imagens de DEV releases vão com tags `-DEV`. Rode o workflow **CLEF Viewer images** manualmente se necessário. Depois, em **GitHub → Packages**, abra cada pacote e defina visibilidade **Public**:

- `ghcr.io/altamir/clef-viewer-server`
- `ghcr.io/altamir/clef-viewer-webapp`

### 2. Deploy no painel

hPanel → VPS → **Docker Manager** → **Compose** → **Compose from URL** (repositório privado: use **Compose manually** e cole o YAML, ou configure [deploy key](https://www.hostinger.com/support/how-to-deploy-from-private-github-repository-on-hostinger-docker-manager/)):

```
https://raw.githubusercontent.com/Altamir/structured_logger/master/apps/clef_viewer/docker-compose.yml
```

**Variáveis de ambiente** no formulário do Docker Manager:

| Variável | Exemplo | Obrigatório |
|----------|---------|-------------|
| `ADMIN_API_KEY` | `openssl rand -hex 32` | sim |
| `INGEST_API_KEY` | `openssl rand -hex 32` | recomendado |
| `CLEF_UI_HOST` | `clef.altamir.dev` | sim (Traefik) |
| `CLEF_INGEST_HOST` | `clef-ingest.altamir.dev` | sim (Traefik) |
| `CLEF_VIEWER_PORT_MAPPING` | `127.0.0.1:5341:5341` | Traefik |
| `CLEF_VIEWER_UI_PORT_MAPPING` | `127.0.0.1:8080:80` | Traefik |

Clique **Deploy**. O Manager puxa as imagens e sobe `server` + `webapp`.

### 3. Firewall da VPS

| Cenário | Liberar no firewall |
|---------|---------------------|
| **Com Traefik** (recomendado) | `80`, `443` (e `22` para SSH). Portas `8080`/`5341` ficam em `127.0.0.1` — não expor. |
| **IP + porta direto** (sem Traefik) | `8080` (webapp/UI), `5341` (ingest SinkSeq). Ajuste no compose: `CLEF_VIEWER_PORT_MAPPING=5341:5341`, `CLEF_VIEWER_UI_PORT_MAPPING=8080:80`. |

### 4. URLs e SinkSeq

| Serviço | URL (Traefik) | Porta local |
|---------|---------------|-------------|
| Web UI | `https://clef.altamir.dev` | `127.0.0.1:8080` |
| Ingest SinkSeq | `https://clef-ingest.altamir.dev` | `127.0.0.1:5341` |

```dart
SinkSeq(
  'https://clef-ingest.altamir.dev',
  apiKey: Platform.environment['INGEST_API_KEY'],
  deviceIdentifier: 'my-app',
);
```

**DNS:** `CLEF_UI_HOST` e `CLEF_INGEST_HOST` → IP da VPS.

**Atualizar:** redeploy no Docker Manager (pull de `:latest`) ou fixe a tag do commit nas variáveis `CLEF_VIEWER_*_IMAGE`.

## Tests

```bash
cd apps/clef_viewer/server && dart test
cd apps/clef_viewer/ui && flutter test
```