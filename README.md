<!-- README.md -->

# Sansbank DAO — Nostr Relay

A shared [Nostr](https://github.com/nostr-protocol/nostr) relay for all
Sansbank DAO projects, served at **`wss://nostr.sansbank.org`**.

One relay instance, operated once, used by every project. Per-project
identity is provided by [NIP-05](https://github.com/nostr-protocol/nips/blob/master/05.md)
identifiers such as `treasury@nostr.sansbank.org`, not by separate relays.

## Stack

| Component | Image | Role |
|---|---|---|
| [Caddy](https://caddyserver.com/) | `caddy:2` | TLS (Let's Encrypt), NIP-05 static file, WebSocket reverse proxy |
| [nostream](https://github.com/Cameri/nostream) | `ghcr.io/cameri/nostream:v3.0.0` | Nostr relay (NIP-01 + more) |
| PostgreSQL | `postgres:15` | Event store |
| Redis | `redis:7.0.5-alpine3.16` | NIP-05 verification cache |
| OpenTelemetry Collector | `otel/opentelemetry-collector-contrib:0.105.0` | OTLP → Prometheus bridge |
| Prometheus | `prom/prometheus:v2.54.0` | Metrics store |
| Grafana | `grafana/grafana:11.2.0` | Dashboards (loopback only) |

```
            :443 (TLS)                 :8008 (loopback)
Internet ─────────────▶ Caddy ─────────────▶ nostream ──┬── PostgreSQL
                          │                             └── Redis
                          ├─ /.well-known/nostr.json        │
                          └─ everything else → WS           └─ OTLP → collector → Prometheus → Grafana
```

## Policy

- **Reads:** open to anyone.
- **Writes:** NIP-05-gated — only authors with a verified NIP-05 identifier
  at `sansbank.org` or `nostr.sansbank.org` may publish (kind `0` metadata
  excepted). Configured in [`config/settings.yaml`](config/settings.yaml).
- **NIP-42:** disabled by decision.
- **Retention:** events older than **365 days** are purged.
- **Media:** not hosted here — files are served from Evolution Drive.
- **Zaps (NIP-57/LNURL):** not enabled.

## Requirements

- The `nostr` VPS: Ubuntu 26.04, 2 vCPU, 3.8 GiB RAM, 33 GiB disk.
- DNS: `nostr.sansbank.org` **A** record → the VPS public IP, **DNS-only
  (grey cloud)**. Cloudflare proxying must stay off so ACME and WebSockets
  reach the origin directly.
- Inbound TCP `80`, `443` and UDP `443` open.

## Documentation

| Doc | Contents |
|---|---|
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | Full first-time setup on a fresh VPS |
| [`docs/NIP05.md`](docs/NIP05.md) | The `/.well-known/nostr.json` file and primary-domain deploy |
| [`docs/OPERATIONS.md`](docs/OPERATIONS.md) | Logs, upgrades, backups, restore, monitoring |

## Quick start (on the VPS)

```bash
sudo apt-get update && sudo apt-get install -y git
sudo git clone https://github.com/sansbankdao/nostr.git /opt/nostream
sudo chown -R "$USER":"$USER" /opt/nostream
cd /opt/nostream

./scripts/install-docker.sh        # docker.io + docker-compose-v2
./scripts/setup-firewall.sh        # ufw: 22, 80, 443
newgrp docker                      # or re-login for docker group

./scripts/generate-secrets.sh      # writes .env with random secrets
./scripts/deploy.sh                # pull image, start stack

./scripts/install-backup-units.sh  # daily PostgreSQL dump timer
```

Verify:

```bash
docker compose ps
curl -s -H 'Accept: application/nostr+json' http://127.0.0.1:8008/ | jq .
curl -s http://127.0.0.1:8008/readyz
curl -s https://nostr.sansbank.org/.well-known/nostr.json | jq .
```

## NIP-05 identities

The identity document lives at [`well-known/nostr.json`](well-known/nostr.json).
Caddy serves it at `https://nostr.sansbank.org/.well-known/nostr.json`; the
same file is intended to be mirrored to
`https://sansbank.org/.well-known/nostr.json`. Names map to **lowercase hex**
public keys. See [`docs/NIP05.md`](docs/NIP05.md).

## Repository layout

```
.
├── Caddyfile                 # TLS + static NIP-05 + WS reverse proxy
├── docker-compose.yml        # the full stack
├── postgresql.conf           # PostgreSQL tuning for the VPS
├── .env.example              # required environment (copy to .env)
├── config/settings.yaml      # nostream policy overrides
├── well-known/nostr.json     # NIP-05 identity document
├── monitoring/               # Prometheus + OTel collector config
├── grafana/                  # Grafana provisioning + dashboard
├── scripts/                  # install / deploy / backup / restore
├── systemd/                  # backup timer units
└── docs/                     # deployment, NIP-05, operations
```

## Operations

```bash
docker compose logs -f nostream     # follow relay logs
./scripts/upgrade.sh                # pull pinned image + migrate
./scripts/backup-db.sh              # manual dump to ./backups
./scripts/restore-db.sh <file.gz>   # restore a dump
ssh -L 7777:127.0.0.1:7777 ubuntu@nostr   # Grafana at http://127.0.0.1:7777
```

## License

MIT — see [`LICENSE`](LICENSE). Copyright (c) 2026 Sansbank DAO.

Note: the relay software (nostream) is MIT-licensed upstream. This repository
is the Sansbank DAO deployment wrapper.