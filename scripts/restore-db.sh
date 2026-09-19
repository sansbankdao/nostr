#!/usr/bin/env bash
# scripts/restore-db.sh <path-to-dump.gz>
#
# Restores a gzip-compressed custom-format pg_dump into the running
# nostream-db container. Stop the relay first to avoid writes during restore:
#   docker compose stop nostream
#   ./scripts/restore-db.sh backups/nostr_ts_relay-<stamp>.dump.gz
#   docker compose start nostream

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <path-to-dump.gz>" >&2
  exit 1
fi

DUMP_GZ="$1"

if [[ ! -f "$DUMP_GZ" ]]; then
  echo "error: file not found: $DUMP_GZ" >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a; source .env; set +a

TMP="$(mktemp -u /tmp/nostream-restore-XXXXXX.dump)"
gunzip -c "$DUMP_GZ" > "$TMP"

docker compose exec -T nostream-db \
  pg_restore -U "${DB_USER}" -d "${DB_NAME}" --clean --if-exists --no-owner < "$TMP"

rm -f "$TMP"

echo "Restore complete from ${DUMP_GZ}"