#!/usr/bin/env bash
# scripts/deploy.sh
#
# Runs on the relay host from the repository root. Prepares the runtime
# directories and settings override, then brings the stack up.
# Idempotent: safe to re-run after a git pull.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "error: .env missing. Run scripts/generate-secrets.sh first." >&2
  exit 1
fi

# Runtime directories expected by the compose bind mounts.
mkdir -p .nostr/data .nostr/db-logs

# Install the settings override on first deploy (preserve on later runs).
if [[ ! -f .nostr/settings.yaml ]]; then
  cp config/settings.yaml .nostr/settings.yaml
fi

# The relay container runs as node (uid 1000) and writes settings.yaml,
# backups and the audit log directly under .nostr.
sudo chown 1000:1000 .nostr .nostr/settings.yaml
chmod 755 .nostr
chmod 600 .nostr/settings.yaml

docker compose pull
docker compose up -d
docker compose ps

echo
echo "Relay should answer on http://127.0.0.1:8008 — verify with:"
echo "  curl -s -H 'Accept: application/nostr+json' http://127.0.0.1:8008/"
echo "  curl -s http://127.0.0.1:8008/readyz"