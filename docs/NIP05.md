<!-- docs/NIP05.md -->

# NIP-05 identities

NIP-05 lets a domain attest that a public key belongs to a named identity.
A client that sees the identifier `<name>@<domain>` requests:

```
https://<domain>/.well-known/nostr.json?name=<name>
```

and expects:

```json
{
  "names": { "<name>": "<lowercase-hex-pubkey>" },
  "relays": { "<lowercase-hex-pubkey>": ["wss://nostr.sansbank.org"] }
}
```

Keys **must** be lowercase hex — `npub1…` is display-only and is rejected by
clients that verify NIP-05.

## This relay's policy

`config/settings.yaml` sets:

```yaml
nip05:
  mode: enabled
  domainWhitelist:
    - sansbank.org
    - nostr.sansbank.org
```

`enabled` means the relay requires a verified NIP-05 for publishing (kind `0`
metadata excepted) and only accepts authors whose identifier is at one of the
allow-listed domains. The relay fetches the author's
`/.well-known/nostr.json` to verify.

## The file

Source of truth in this repository: [`../well-known/nostr.json`](../well-known/nostr.json).

It ships **empty**:

```json
{
  "names": {},
  "relays": {}
}
```

Populate `names` with `"name": "<hex pubkey>"` entries, and `relays` with the
same pubkeys listing `wss://nostr.sansbank.org`. Names use only `a-z0-9-_.`
and lowercase is required.

## Where it is served

1. **`https://nostr.sansbank.org/.well-known/nostr.json`** — served by Caddy
   from this repository (see the `handle /.well-known/nostr.json` block in
   `Caddyfile`). This is the path Sansbank DAO controls directly.
2. **`https://sansbank.org/.well-known/nostr.json`** — the primary domain is
   fronted by Cloudflare and points to a different origin. The same file must
   be published there by whoever operates the primary site. Verified on
   2026-09-19: `sansbank.org` resolves to Cloudflare (`172.64.80.1`) and
   `/.well-known/nostr.json` returns `404`.

Because both domains are allow-listed, an identity published on either resolves.
An identity on `sansbank.org` only verifies once the file is live on the
primary origin.

## Adding an identity

1. Add both the `names` and `relays` entries in `well-known/nostr.json`.
2. Commit and deploy (`git pull` + `./scripts/deploy.sh`; Caddy serves the file
   from the bind mount directly, so a `docker compose restart caddy` is
   unnecessary).
3. Set the same identifier in the project's kind `0` metadata `nip05` field.
4. Confirm:

```bash
curl -s 'https://nostr.sansbank.org/.well-known/nostr.json?name=<name>' | jq .
```