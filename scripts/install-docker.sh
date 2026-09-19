#!/usr/bin/env bash
# scripts/install-docker.sh
#
# Installs Docker Engine and the Compose v2 plugin from the Ubuntu archive,
# enables the daemon, and grants the invoking user docker access.
# Verified target: Ubuntu 26.04.1 LTS, packages docker.io (29.1.3) and
# docker-compose-v2 (2.40.3).

set -euo pipefail

sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2

sudo systemctl enable --now docker

# Allow the current user to run docker without sudo (group change takes
# effect on next login).
sudo usermod -aG docker "$(id -un)"

echo
echo "Docker installed:"
docker --version
docker compose version
echo
echo "Log out and back in (or run 'newgrp docker') before using docker as $(id -un)."