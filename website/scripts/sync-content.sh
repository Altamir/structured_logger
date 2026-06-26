#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

sync_dir() {
  local src="$1"
  local dest="$2"
  local delete_flag="${3:-true}"
  shift 3 || true
  local -a excludes=("$@")

  if [[ ! -d "${src}" ]]; then
    echo "error: source not found at ${src}" >&2
    exit 1
  fi

  mkdir -p "${dest}"

  local -a rsync_args=(-av)
  if [[ "${delete_flag}" == "true" ]]; then
    rsync_args+=(--delete)
  fi
  for pattern in "${excludes[@]}"; do
    rsync_args+=(--exclude "${pattern}")
  done

  rsync "${rsync_args[@]}" "${src}/" "${dest}/"
  echo "Synced: ${src} -> ${dest}"
}

# pt-BR blog (default locale)
sync_dir "${ROOT_DIR}/doc/blog" "${ROOT_DIR}/website/blog" true README.md

# en docs and blog (i18n)
sync_dir "${ROOT_DIR}/doc/en" "${ROOT_DIR}/website/i18n/en/docusaurus-plugin-content-docs/current" true blog README.md
sync_dir "${ROOT_DIR}/doc/en/blog" "${ROOT_DIR}/website/i18n/en/docusaurus-plugin-content-blog" false README.md