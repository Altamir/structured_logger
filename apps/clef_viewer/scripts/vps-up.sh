#!/usr/bin/env bash
# Conveniência local — na VPS/Hostinger use apenas: docker compose up -d
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Create .env from .env.example and set ADMIN_API_KEY."
  exit 1
fi

docker compose up -d "$@"