#!/usr/bin/env bash
# scripts/install-backup-units.sh
#
# Installs and enables the daily PostgreSQL backup systemd timer.
# Assumes the repository is deployed at /opt/nostream.

set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"

if [[ "$REPO_ROOT" != "/opt/nostream" ]]; then
  echo "warning: repository is at ${REPO_ROOT}, but the systemd unit expects /opt/nostream" >&2
fi

sudo install -m 644 systemd/nostream-backup.service /etc/systemd/system/nostream-backup.service
sudo install -m 644 systemd/nostream-backup.timer /etc/systemd/system/nostream-backup.timer

sudo systemctl daemon-reload
sudo systemctl enable --now nostream-backup.timer

sudo systemctl status nostream-backup.timer --no-pager
systemctl list-timers nostream-backup.timer --no-pager