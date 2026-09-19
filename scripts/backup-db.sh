#!/usr/bin/env bash
# scripts/backup-db.sh
#
# Dumps the nostream PostgreSQL database in custom format, gzips it, and
# prunes dumps older than RETENTION_DAYS. Intended to run from a systemd
# timer (see systemd/nostream-backup.timer) or cron.

set -euo pipefail

cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
set -a; source .env; set +a

BACKUP_DIR="${BACKUP_DIR:-${PWD}/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${BACKUP_DIR}/${DB_NAME}-${STAMP}.dump"

docker compose exec -T nostream-db \
  pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc > "${OUT}"

gzip -f "${OUT}"

# Prune old dumps.
find "$BACKUP_DIR" -type f -name "${DB_NAME}-*.dump.gz" -mtime "+${RETENTION_DAYS}" -delete

echo "Backup written: ${OUT}.gz"