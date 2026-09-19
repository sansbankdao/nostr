#!/usr/bin/env bash
# scripts/upgrade.sh
#
# Pulls the pinned nostream image and recreates the relay so migrations run,
# without touching Postgres/Redis data volumes.

set -euo pipefail

cd "$(dirname "$0")/.."

docker compose pull nostream nostream-migrate
docker compose up -d --force-recreate nostream-migrate nostream
docker compose ps