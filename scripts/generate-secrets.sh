#!/usr/bin/env bash
# scripts/generate-secrets.sh
#
# Creates .env from .env.example with freshly generated SECRET, DB_PASSWORD,
# REDIS_PASSWORD and GRAFANA_ADMIN_PASSWORD values. Refuses to overwrite an
# existing .env.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  echo "error: .env already exists — refusing to overwrite." >&2
  exit 1
fi

SECRET="$(openssl rand -hex 64)"
DB_PASSWORD="$(openssl rand -hex 32)"
REDIS_PASSWORD="$(openssl rand -hex 32)"
GRAFANA_ADMIN_PASSWORD="$(openssl rand -hex 32)"

sed \
  -e "s|^SECRET=.*|SECRET=${SECRET}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" \
  -e "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASSWORD}|" \
  -e "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}|" \
  .env.example > .env

chmod 600 .env

echo "Wrote .env (mode 600)."