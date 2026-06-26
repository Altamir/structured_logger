#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Copy .env.example to .env and set ADMIN_API_KEY first."
  exit 1
fi

COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.build.yml -f docker-compose.dev.yml)

if command -v flutter >/dev/null 2>&1; then
  echo "Building Flutter Web locally..."
  (cd ui && flutter pub get && flutter build web --release --dart-define=CLEF_VIEWER_API=)
  COMPOSE+=(-f docker-compose.prebuilt.yml)
fi

DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 "${COMPOSE[@]}" up --build "$@"