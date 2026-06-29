#!/usr/bin/env bash
set -euo pipefail

# Creates v{version} git tags for publishable workspace packages.
# Used after `melos version --no-git-tag-version`.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for dir in packages/structured_logger packages/structured_logger_dio_interceptor; do
  pubspec="${root}/${dir}/pubspec.yaml"
  ver=$(grep '^version:' "$pubspec" | awk '{print $2}')
  tag="v${ver}"

  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "skip ${tag} (already exists)"
  else
    git tag "$tag"
    echo "created ${tag}"
  fi
done