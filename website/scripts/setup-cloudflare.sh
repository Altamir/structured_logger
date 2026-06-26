#!/usr/bin/env bash
set -euo pipefail

# One-time setup: create Pages project, build, deploy, add custom domain.
# Requires: wrangler logged in (`wrangler login`) or CLOUDFLARE_API_TOKEN set.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_NAME="structured-logger"
CUSTOM_DOMAIN="structured-logger.altamir.dev"
PRODUCTION_BRANCH="master"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-9da0c90849945330726c5272d56b74d8}"

cd "${ROOT_DIR}"

echo "→ Sync content"
bash website/scripts/sync-content.sh

echo "→ Ensure Pages project exists"
wrangler pages project create "${PROJECT_NAME}" --production-branch="${PRODUCTION_BRANCH}" 2>/dev/null || true

echo "→ Build site"
(cd website && npm ci && npm run build)

echo "→ Deploy to Cloudflare Pages"
wrangler pages deploy website/build \
  --project-name="${PROJECT_NAME}" \
  --branch="${PRODUCTION_BRANCH}" \
  --commit-dirty=true

if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "→ Add custom domain ${CUSTOM_DOMAIN}"
  curl -fsS -X POST \
    "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"name\":\"${CUSTOM_DOMAIN}\"}" >/dev/null || true
else
  echo "→ Skipping custom domain API step (set CLOUDFLARE_API_TOKEN to run via API)"
  echo "  Or add ${CUSTOM_DOMAIN} manually in Cloudflare Pages → ${PROJECT_NAME} → Custom domains"
fi

echo ""
echo "Done."
echo "  Pages URL:  https://${PROJECT_NAME}.pages.dev"
echo "  Custom URL: https://${CUSTOM_DOMAIN} (may take a few minutes for SSL)"