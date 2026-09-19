<!-- docs/DEPLOYMENT.md -->

# Deployment

First-time setup of the shared relay on the `nostr` VPS.

## 0. Prerequisites

- SSH access to `ubuntu@nostr` (the host resolves via `~/.ssh/config`).
- DNS: `nostr.sansbank.org` **A** → the VPS public IP, DNS-only
  (grey cloud). Verified target IP for this environment: `172.81.181.31`.
- Host: Ubuntu 26.04, 2 vCPU, 3.8 GiB RAM, 33 GiB disk.

## 1. Base packages

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git vim
```

## 2. Clone the repository

```bash
sudo mkdir -p /opt/nostream
sudo chown "$USER":"$USER" /opt/nostream
git clone https://github.com/sansbankdao/nostr.git /opt/nostream
cd /opt/nostream
```

(If the repository is private, use an SSH deploy key instead of HTTPS.)

## 3. Install Docker

```bash
./scripts/install-docker.sh
newgrp docker        # or log out and back in
docker --version
docker compose version
```

## 4. Firewall

```bash
./scripts/setup-firewall.sh
```

This denies inbound by default and allows `22/tcp`, `80/tcp`, `443/tcp`,
`443/udp`.

## 5. Secrets

```bash
./scripts/generate-secrets.sh
```

Creates `.env` (mode 600) with random `SECRET`, `DB_PASSWORD`,
`REDIS_PASSWORD` and `GRAFANA_ADMIN_PASSWORD`. `DB_USER` stays
`nostr_ts_relay`, matching the healthchecks in `docker-compose.yml`.

## 6. NIP-05 document

Populate `well-known/nostr.json` with real hex public keys before writers
depend on it. The relay runs NIP-05-gated (`nip05.mode: enabled` in
`config/settings.yaml`); until a name resolves in this file, that author
cannot publish. See [`NIP05.md`](NIP05.md).

## 7. Deploy

```bash
./scripts/deploy.sh
```

This creates `.nostr/`, installs `.nostr/settings.yaml` from
`config/settings.yaml`, pulls `ghcr.io/cameri/nostream:v3.0.0`, runs the
migration container, and starts the stack.

## 8. Verify

```bash
docker compose ps
curl -s http://127.0.0.1:8008/readyz
curl -s -H 'Accept: application/nostr+json' http://127.0.0.1:8008/ | jq .
curl -s https://nostr.sansbank.org/.well-known/nostr.json | jq .
```

Caddy obtains the Let's Encrypt certificate on first request; watch it with:

```bash
docker compose logs -f caddy
```

## 9. Backups

```bash
./scripts/install-backup-units.sh
systemctl list-timers nostream-backup.timer
```

Dumps land in `/opt/nostream/backups` and are pruned after 7 days by
default.

## Updating the deployment

```bash
cd /opt/nostream
git pull
./scripts/deploy.sh        # re-applies compose/config changes
./scripts/upgrade.sh       # only needed to recreate the relay image
```

When the nostream image tag in `docker-compose.yml` changes, run
`./scripts/upgrade.sh` so the migration container re-runs.