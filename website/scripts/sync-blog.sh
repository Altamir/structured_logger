#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${ROOT_DIR}/docs/blog"
DEST="${ROOT_DIR}/website/blog"

if [[ ! -d "${SRC}" ]]; then
  echo "error: blog source not found at ${SRC}" >&2
  exit 1
fi

mkdir -p "${DEST}"

rsync -av --delete \
  --exclude 'README.md' \
  "${SRC}/" "${DEST}/"

echo "Synced blog: ${SRC} -> ${DEST}"