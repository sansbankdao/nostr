<!-- docs/OPERATIONS.md -->

# Operations

Runbook for the shared relay. All commands run from `/opt/nostream` on the
`nostr` VPS unless noted.

## Status

```bash
cd /opt/nostream
docker compose ps
curl -s http://127.0.0.1:8008/readyz
```

`/readyz` returns `200` when PostgreSQL and Redis respond, `503` otherwise.

## Logs

```bash
docker compose logs -f nostream     # relay
docker compose logs -f caddy        # TLS + access log
docker compose logs -f nostream-db   # PostgreSQL
```

Caddy also writes a rolling access log inside the `caddy-data` volume at
`/data/access.log`.

## Upgrade the relay

The image is pinned by digest in `docker-compose.yml`
(`ghcr.io/cameri/nostream@sha256:de86cc75…`, the `:main` build). Do not pin the
`v3.0.0` tag: that image is missing `/app/knexfile.js` and `/app/migrations`,
so `nostream-migrate` fails with `No configuration file found` and the relay
starts against an empty database. To move to a new release:

1. Resolve the digest of the desired build:

```bash
sudo docker pull ghcr.io/cameri/nostream:main
sudo docker image inspect ghcr.io/cameri/nostream:main --format '{{index .RepoDigests 0}}'
```

2. Replace the `image:` value on both the `nostream` and `nostream-migrate`
   services in `docker-compose.yml`.
3. Run:

```bash
./scripts/upgrade.sh
```

`upgrade.sh` pulls the image and recreates `nostream-migrate` (so schema
migrations run) followed by `nostream`. PostgreSQL and Redis data volumes are
untouched.

### Bind-mounted config files

`Caddyfile`, `postgresql.conf` and the files under `monitoring/` are bind
mounts, not part of an image. `docker compose up -d` does **not** restart a
container when only a bind-mounted file changes, so the running container keeps
the old file. After editing one:

| File changed | Required command |
|---|---|
| `Caddyfile` | `docker compose restart caddy` |
| `postgresql.conf` | `docker compose restart nostream-db` |
| `monitoring/*.yaml` | `docker compose restart otel-collector prometheus` |

The contents of `well-known/` are served from the bind mount on each request,
so a NIP-05 update needs no restart. Confirm what a container actually sees
with `docker compose exec caddy cat /etc/caddy/Caddyfile`.

## Backups

Automatic: `systemd/nostream-backup.timer` runs daily at 03:15 UTC.

```bash
systemctl list-timers nostream-backup.timer
journalctl -u nostream-backup.service -n 50
ls -lh backups/
```

Manual dump:

```bash
./scripts/backup-db.sh
```

Dumps are PostgreSQL custom-format, gzip-compressed, named
`nostr_ts_relay-<UTC timestamp>.dump.gz`, pruned after 7 days
(`RETENTION_DAYS` overrides).

Restore:

```bash
docker compose stop nostream
./scripts/restore-db.sh backups/nostr_ts_relay-<stamp>.dump.gz
docker compose start nostream
```

## Monitoring

Prometheus and Grafana bind to loopback only. Reach Grafana through an SSH
tunnel:

```bash
ssh -L 7777:127.0.0.1:7777 ubuntu@nostr
# then open http://127.0.0.1:7777
```

- Prometheus: `ssh -L 9090:127.0.0.1:9090 ubuntu@nostr` → `http://127.0.0.1:9090`
- The `Nostream` folder contains the provisioned overview dashboard.
- Grafana anonymous viewing is enabled (Viewer role); the admin password is
  `GRAFANA_ADMIN_PASSWORD` in `.env`.

## Disk

Events are retained 365 days. Check usage:

```bash
df -h /
docker system df
du -sh .nostr/data backups
```

Reclaim unused images:

```bash
docker image prune -f
```

## Common tasks

| Task | Command |
|---|---|
| Restart relay only | `docker compose restart nostream` |
| Apply a settings change | `cp config/settings.yaml .nostr/settings.yaml && docker compose restart nostream` |
| Reload Caddy config | `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile` |
| Postgres shell | `docker compose exec nostream-db psql -U nostr_ts_relay -d nostr_ts_relay` |
| Event count | `docker compose exec nostream-db psql -U nostr_ts_relay -d nostr_ts_relay -c 'select count(*) from events;'` |

## Troubleshooting

- **No writes accepted.** `nip05.mode: enabled` is in effect. Confirm the
  author's identifier resolves (`docs/NIP05.md`) and that the identifier's
  domain is in `domainWhitelist`.
- **Certificate not issued.** Confirm `nostr.sansbank.org` is DNS-only
  (grey cloud) and that TCP 80/443 reach the origin. Check
  `docker compose logs caddy`.
- **`/readyz` 503.** Inspect `docker compose logs nostream-db nostream-cache`
  and `docker compose ps`.