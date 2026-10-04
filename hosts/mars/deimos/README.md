# deimos

deimos is the application LXC on the `mars` TrueNAS box. It runs most
self-hosted workloads as Podman quadlets (media, photos, AI, monitoring,
smart home, network controller).

- NixOS (x86_64) in an Incus LXC (`marsLxcBase`), LAN IP `192.168.1.13`
- wg0 backbone IP `10.10.1.18`, plus NetBird (`wt0`)
- UI-only state and known quirks: see [Operational notes](#operational-notes)

## Storage

| Path | Purpose |
| :--- | :--- |
| `/mnt/nvme-pool/apps/<app>` | Container state (SQLite, configs, DB dirs), owned by `apps` (568) |
| `/mnt/pool/*` | Bulk HDD datasets: media libraries, photos |

The Incus disk devices must be recursive for child datasets to show up in the
container (see `learned-facts.md`).

## Ingress and DNS

- Traefik owns 80/443 and discovers containers via Podman labels on the
  `proxy` network (`172.30.0.0/24`). Certificates: Let's Encrypt DNS-01 via
  Cloudflare.
- Hostnames follow `<app>.deimos.mars.lukashirsch.de`. Blocky on deimos and on
  mercury resolves them to `10.10.1.18` for VPN clients; `ddns-updater` keeps
  the public `mars` / `*.mars` records current.
- SSO: apps with OIDC use Authelia on mercury. Jellyfin uses the Authelia
  plugin instead (see [Jellyfin + Authelia](#jellyfin--authelia)).
- Firewall ports are listed in `stacks/default.nix`.

## Services

| Stack file | Services |
| :--- | :--- |
| `stacks/traefik.nix` | Traefik (+ `proxy` network) |
| `stacks/blocky.nix` | Blocky DNS |
| `stacks/ddns-updater.nix` | DDNS updater |
| `stacks/media.nix` | Jellyfin, Seerr, Jellystat, Prowlarr, SABnzbd, Sonarr and Radarr (original / german / anime), Recyclarr, Muxarr, Reclaimerr, Houndarr, FlareSolverr, Gluetun (VPN egress) |
| `stacks/immich.nix` | Immich (server, ML, Valkey, Postgres), Immich Power Tools |
| `stacks/ai.nix` | Open WebUI, LiteLLM |
| `stacks/mealie.nix` | Mealie (recipes, OIDC via Authelia) |
| `stacks/monitoring.nix` | Grafana, Loki, InfluxDB, Scrutiny |
| `stacks/monitoring.nix` (Gatus part) | Gatus uptime dashboard (`gatus.deimos…`, OIDC via Authelia); checks in `gatusChecks.deimos`, container in `modules/nixos/gatus.nix` |
| `stacks/smarthome.nix` | ESPHome, Mosquitto, Zigbee2MQTT |
| `stacks/omada.nix` | Omada controller |
| `stacks/syncthing.nix` | Syncthing |
| `stacks/feuerwehr.nix` | FileBrowser (fire-brigade photos) |

Other host modules: `vpn.nix` (wg0, NetBird), `monitoring.nix` (Alloy
shipping logs/metrics).

## Runtime policy

- Quadlets via NixOS; containers use `autoUpdate = "registry"` and
  `Restart = "always"`.
- Secrets come from `secrets/stacks-mars-deimos.yaml` (sops-nix) and are
  rendered to env files by sops templates.

## Deploy

From `lkshrsch-workstation` (builds locally):

```bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --target-host root@192.168.1.13
```

## Operational notes

State below lives in web UIs or on disk, not in Nix.

### Grafana service account (Claude MCP)

The repo-level `.mcp.json` runs `grafana/mcp-grafana` read-only. Create
`Administration → Service accounts → claude-mcp` (role **Viewer**), add a
token, and store it in `secrets/secrets.yaml` as `mcp/grafana/token`
(`mcp/grafana/url` = Grafana base URL).

### Arr instances (shared by Muxarr, Reclaimerr, Houndarr)

Connect all six using media-network DNS names and **internal** ports (not the
published 787x/898x host ports). API keys: each arr's
`Settings → General → API Key`.

- Sonarr: `http://sonarr-{anime,german,original}:30027`
- Radarr: `http://radarr-{anime,german,original}:30025`
- Library paths are identical in every container: `/mnt/anime/{series,movies}`,
  `/mnt/series/{german,original}`, `/mnt/movies/{german,original}`.

### Recyclarr

Image is `docker.io/recyclarr/recyclarr` (v8+; tags have no leading `v`). The
upstream `config-templates` `v8` branch is empty, so includes fail with
`Unable to find include template with name '…'`. Fix (applied 2026-06-17): pin
`master` in `/mnt/nvme-pool/apps/recyclarr/configuration/settings.yml`:

```yaml
resource_providers:
  - type: config-templates
    name: official-config-templates
    clone_url: https://github.com/recyclarr/config-templates.git
    reference: master
    replace_default: true
```

Re-check after a v9+ bump; drop the pin once the version branch is populated.

### Jellyfin + Authelia

`jellyfin-plugin-authelia` authenticates against Authelia's HTTP API, not
OIDC, so no OIDC client is needed in `hosts/mercury/stacks/authelia.nix`.

1. `Dashboard → Plugins → Catalog`: add the manifest
   `https://raw.githubusercontent.com/nikarh/jellyfin-plugin-authelia/main/manifest.json`
   and install "Authelia Authentication".
2. In the plugin settings set the **Authelia Server URL**, the **Jellyfin
   URL** (must match the `X-Original-URL` Authelia sees, otherwise auth fails
   with correct credentials) and the admin group mapping.

Authelia must keep a `one_factor` policy (plugin has no 2FA; use
`jellyfin-sso-plugin` for that). Today `default_policy: one_factor` covers
it; add an `access_control` rule for the Jellyfin domain only if the default
is ever tightened to `deny`. A custom `server.endpoints.authz` block must
keep `implementation: 'AuthRequest'`. Jellyfin 12 is supported since plugin
1.0.17.

### Muxarr

Data: `/mnt/nvme-pool/apps/muxarr/data` (SQLite).

1. Open `https://muxarr.deimos.mars.lukashirsch.de` and create the admin
   user in the setup wizard.
2. Connect the arrs and create one profile per library (see above).
3. Add a webhook in each arr (`Settings → Connect → Webhook`) to
   `http://muxarr:8183` (copy the exact URL Muxarr shows) so imports are
   processed automatically.
4. **Preview** planned track removals on a few files per library before
   queueing bulk jobs: Muxarr rewrites files in place.

### Reclaimerr

Data: `/mnt/nvme-pool/apps/reclaimerr/data` (SQLite + generated
`secrets.env`; sops env overrides the JWT/encryption secrets). Back it up
before upgrades.

1. Create the admin account on first visit.
2. Connect Jellyfin at `http://jellyfin:8096` as main server, then the arrs.
3. Set `Application URL` to `https://reclaimerr.deimos.mars.lukashirsch.de`.
4. Deletion is opt-in twice (cleanup deletion **and** the
   delete-cleanup-candidates task). Review candidates before enabling either.

### Houndarr

Drip-feeds missing/cutoff-unmet searches to the arrs so indexer API caps are
not exhausted. Data: `/mnt/nvme-pool/apps/houndarr/data` (SQLite +
`houndarr.masterkey`, which encrypts the stored arr API keys: treat backups as
secret). First boot may run DB migrations for several minutes.

1. `/setup` creates the single admin account (dead after first use).
2. `Settings → Add Instance` for all six arrs.
3. Phase 1 (missing only), per instance: `Batch Size 1`, `Hourly Cap 1`,
   `Sleep 30` min, `Cooldown 30` days, `Post-Release Grace 12` h,
   `Queue Limit 10`, window `02:00-06:00`, order `random`, cutoff and upgrade
   passes off. Ceiling ≈ 24 API hits/day per shared indexer.
4. Phase 2 (once the missing backlog stabilises; **still pending**): enable the
   cutoff pass with `Cutoff Batch 1`, `Cutoff Cap 1`, `Cutoff Cooldown 45`
   days. Leave the *upgrade* pass off: it re-searches items already at cutoff.
5. Sonarr: use `Season-context search` while backfilling, episode mode after.
   To go faster, widen the time window rather than raising hourly caps.

### Known cosmetic failure: `systemd-tmpfiles-clean`

`systemctl --failed` shows `systemd-tmpfiles-clean.service` failing with
`statx(/tmp) failed: Protocol driver not attached`
([systemd#41227](https://github.com/systemd/systemd/issues/41227), systemd
260.1 on `noatime` LXC roots; affects all Mars containers since 2026-06-17).
No functional impact; `/tmp` cleanup is skipped. Goes away once the fix is
backported to `nixos-26.05` and the containers are redeployed. Remove this
note when `systemctl --failed` is clean.

## Changelog

High-level, newest first. Details live in `git log -- hosts/mars/deimos`.

- 2026-10-04: **Gatus added** (`stacks/monitoring.nix`), cross-watching mercury.
- 2026-10-04: **Mealie moved here from mercury** (`stacks/mealie.nix`).
- 2026-09: Muxarr, Reclaimerr and Houndarr added to the media stack;
  Jellyfin Authelia plugin documented.
- 2026-06: Upgraded to NixOS 26.05; Recyclarr pinned to v8 config templates.
- 2026-03: VPN configuration changed.
- 2026-02: Omada controller added; WireGuard fixes; stack permissions fixed.
- 2026-01: ddns-updater added; media stack improved; Tailscale removed in
  favour of NetBird.
- 2025-12: AI stack (Open WebUI) and Immich hardware acceleration added;
  wg-quick VPN support.
- 2025-11: Blocky, Immich, media, monitoring, smart-home, Syncthing and
  FileBrowser stacks added; quadlet-nix adopted.
- 2025-10: WireGuard backbone across the Mars containers.
- 2025-07/08: Initial Mars LXC configuration with Podman.
