# deimos

deimos is the application LXC on the `mars` TrueNAS box. It runs most
self-hosted workloads as Podman quadlets (media, photos, AI, smart home,
network controller). Traefik, Grafana, Loki, Prometheus, graphite-exporter and
Gatus run natively.

- NixOS (x86_64) in an Incus LXC (`marsLxcBase`), LAN IP `192.168.1.13`
- wg0 backbone IP `10.10.1.18`, plus NetBird (`wt0`)
- UI-only state: see [Operational notes](#operational-notes); per-app setup
  notes live in [`learned-facts.md`](../../../.claude/learned-facts.md)

## Hardware

deimos shares the `mars` host with [phobos](../phobos/README.md). Values from
TrueNAS (`midclt call system.info`, `virt.instance.query`), 2026-11.

| Component | Detail |
| :--- | :--- |
| Host OS | TrueNAS SCALE 25.10 (Incus instances) |
| CPU | AMD Ryzen 7 7700X, 8 cores (SMT off) |
| RAM | 64 GB DDR5 ECC (shared with ZFS ARC and phobos) |
| iGPU | AMD Raphael (`0000:0b:00.0`), passed through to deimos |
| Network | Mellanox ConnectX-3, 10 GbE fibre (`enp10s0`, bridged as `br1`) |
| HBA | Broadcom / LSI SAS3416 (bulk HDDs) |
| `pool` | RAIDZ2, 8 × 4 TB Toshiba MG04SCA40EE (SAS) |
| `nvme-pool` | Mirror, Corsair Force MP510 960 GB + Samsung 970 EVO Plus 2 TB |
| `boot-pool` | Mirror, Crucial BX500 240 GB + Samsung 850 EVO 250 GB |

### Instance limits

| Setting | Value |
| :--- | :--- |
| Memory | **18 GiB** hard limit (`memory.max`); all containers share it |
| CPU | No limit; all 8 host cores |
| Autostart | Off in TrueNAS |
| Passthrough | iGPU (`/dev/dri`, hardware transcoding), USB ConBee II Zigbee stick |

The 18 GiB cap covers every container on deimos together. When it is hit,
the kernel OOM-kills processes inside deimos; the host's free RAM does not
help.

## Storage

Incus disk devices (TrueNAS → container, same path on both sides):

| Path | Purpose |
| :--- | :--- |
| `/mnt/nvme-pool/apps/<app>` | Container state (SQLite, configs, DB dirs), owned by `apps` (568) |
| `/mnt/pool/media` | Media libraries |
| `/mnt/pool/photos` | Photo libraries (Immich, FileBrowser) |
| `/mnt/pool/home` | Home datasets |

The Incus disk devices must be recursive for child datasets to show up in the
container (see `learned-facts.md`). UIDs 508 (`omada`), 568 (`apps`), 1883
(`mqtt`) and 3005 (`openvad`) are mapped 1:1 to the host (TrueNAS users with
`userns_idmap: DIRECT`, applied to every instance on its next start); every
other UID lands in the unprivileged range.

## Ingress and DNS

- Traefik is a native NixOS service (`modules/nixos/traefik.nix`, part of the
  server role `modules/nixos/server.nix`) and owns 80/443. It does no
  container discovery: each feature file declares its routes in
  `services.traefik.routes` next to its container, and every container on the
  `proxy` network (`172.30.0.0/24`) has a pinned address, kept in a `let` of
  that feature file and used for both the network pin and the route URL.
  Nothing checks the pins for uniqueness. Traefik restarts on every route
  change (no reload). Certificates: Let's Encrypt DNS-01 via Cloudflare, state
  in `/var/lib/traefik`.
- Hostnames follow `<app>.deimos.mars.lukashirsch.de`. Blocky on deimos and on
  mercury resolves them to `10.10.1.18` for VPN clients; `ddns-updater` keeps
  the public `mars` / `*.mars` records current.
- SSO: apps with OIDC use Authelia on mercury. Jellyfin authenticates through
  the Authelia HTTP API plugin instead of OIDC.
- Firewall ports are listed in `stacks/default.nix`.

## Services

| Stack file | Services |
| :--- | :--- |
| `stacks/default.nix` | Firewall and the `proxy` network |
| `stacks/blocky.nix` | Blocky DNS |
| `stacks/ddns-updater.nix` | DDNS updater |
| `stacks/media.nix` | Jellyfin and the media automation stack (own `media` network, Gluetun VPN egress) |
| `stacks/immich.nix` | Immich (server, ML, Valkey, Postgres) |
| `stacks/ai.nix` | Open WebUI, LiteLLM |
| `stacks/mealie.nix` | Mealie (recipes, OIDC via Authelia) |
| `stacks/scrutiny.nix` | Scrutiny and its InfluxDB (also a Grafana datasource), own `monitoring` network |
| `stacks/smarthome.nix` | ESPHome, Mosquitto, Zigbee2MQTT |
| `stacks/omada.nix` | Omada controller and its Traefik route |
| `stacks/syncthing.nix` | Syncthing |
| `stacks/feuerwehr.nix` | FileBrowser (fire-brigade photos) |

`stacks/` holds only Podman containers. Native services live in host modules:

| Host file | Services |
| :--- | :--- |
| `traefik.nix` | Native Traefik host settings (shared module `modules/nixos/traefik.nix`, dashboard route from the server role), sops env file, `internal-ipallowlist` |
| `monitoring.nix` | Native Grafana, Loki, Prometheus (remote-write receiver at `prometheus.deimos…`, basic auth shared with Loki, no pull jobs), graphite-exporter, the mars syslog listener and Gatus (`gatus.deimos…`, OIDC via Authelia, state in `/var/lib/gatus`). The scrapes of Grafana, Loki, Prometheus and graphite-exporter are one Alloy file (`alloy/monitoring.alloy`) |
| `vpn.nix` | wg0, NetBird |

Alloy (`modules/nixos/alloy.nix` plus the server role) pushes logs and metrics
to Loki and Prometheus on this host; each service declares its scrape as an
`/etc/alloy/<name>.alloy` file next to itself (Blocky in `stacks/blocky.nix`,
InfluxDB in `stacks/scrutiny.nix`).

## Runtime policy

- Quadlets via NixOS; containers use `autoUpdate = "registry"` and
  `Restart = "always"`. Traefik, Grafana, Loki, Prometheus, graphite-exporter
  and Gatus are plain NixOS services, not quadlets.
- Secrets come from `secrets/stacks-mars-deimos.yaml` (sops-nix) and are
  rendered to env files by sops templates.
- Hardware config comes from `facter.json` (`nixos-facter`, regenerated
  2026-11-17). Regenerate with:

  ```bash
  ssh root@192.168.1.13 'nix run nixpkgs#nixos-facter -- -o /dev/stdout' > hosts/mars/deimos/facter.json
  ```

## Deploy

From `lkshrsch-workstation` (builds locally):

```bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --target-host root@192.168.1.13
```

## Operational notes

State below lives in web UIs, on disk or in TrueNAS, not in Nix.

### Grafana service account (Claude MCP)

The repo-level `.mcp.json` runs `grafana/mcp-grafana` read-only. Create
`Administration → Service accounts → claude-mcp` (role **Viewer**), add a
token, and store it in `secrets/secrets.yaml` as `mcp/grafana/token`
(`mcp/grafana/url` = Grafana base URL).

### Scrutiny collector on mars

The SMART and ZFS collectors run on the `mars` host, not in this container:
TrueNAS cron jobs 4 (`scrutiny-collector-metrics`) and 5
(`scrutiny-collector-zfs`), daily at 00:15, binaries in
`/mnt/nvme-pool/apps/scrutiny/bin/`. Both post to
`https://scrutiny.deimos.mars.lukashirsch.de` with `--host-id mars`. If the
Scrutiny URL or port changes, update both cron jobs in the TrueNAS UI
(`System → Advanced → Cron Jobs`); they discard nothing now, so failures show
in the job log.

### Ports

Port 8081 is taken by a `conmon` process (Podman's container monitor). Use 8082
or another free port for new host services.

### FileBrowser Quantum (`stacks/feuerwehr.nix`)

- The image reads `/home/filebrowser/data/config.yaml` and exits if it is
  missing, unless `FILEBROWSER_CONFIG` points at a valid file. Persist the
  single `/home/filebrowser/data` directory (not the old `/database` and
  `/config` split).
- Mount the browsed tree at the path used in `server.sources` (photos at
  `/srv`, source path `/srv`). A tree owned by `apps:apps` is readable by a
  container running as `568:568`.
- HEIC/HEIF previews need
  `integrations.media.convert.imagePreview.heic: true` and FFmpeg, which the
  `-slim` images lack: use the non-slim tag.

### Media stack (`stacks/media.nix`)

App data, databases and logs are on mars under `/mnt/nvme-pool/apps/<app>/`.
Read them with `sqlite3 "file:<db>?mode=ro"` over `ssh root@192.168.1.16`:

- Sonarr: `configuration-{original,german,anime}/sonarr.db`, logs in
  `logs/sonarr*.txt` (CET). Trace "who added or deleted X" through the log's
  `AddSeriesService`/`ImportListSyncService` lines and Seerr's
  `[Sonarr] Removed series`.
- Jellyseerr `configuration/db/db.sqlite3`, Houndarr `data/houndarr.db`
  (`search_log`), SABnzbd `configuration/admin/` (`queue10.sab`,
  `history1.db`), Reclaimerr `data/database/reclaimerr.db`
  (`reclaim_rules.definition`, `lifecycle_events`).

Gotchas:

- **sonarr-german re-adds deleted series.** Its `SonarrImport` list
  `sonarr-original` (profile 1, tag `2`, auto-add and search missing) re-adds a
  tag-2 series deleted only in sonarr-german (or through Seerr "remove") within
  about 5 minutes and re-grabs every episode. Delete with "Add List Exclusion"
  ticked, or remove tag 2 in sonarr-original. sonarr-anime's `AniListImport`
  list sets tag `anilist-lkshrsch`; radarr-anime has no list.
- **Houndarr** searches show in Sonarr history as `UserInvokedSearch` and touch
  no HDD; each grab ends in a full-copy import (NVMe to pool) plus an in-place
  muxarr remux. Sonarr/Radarr task intervals (Refresh Series 12 h,
  RefreshMovie 24 h) are hardcoded; "Rescan Series/Movie Folder after Refresh"
  controls their disk reads.
- **Reclaimerr API** has two auth tiers. `rcl_…` tokens work only as
  `Authorization: Bearer` on `/api/v1/*` (read tasks, rules and candidates; run
  tasks; postpone or protect candidates). Schedules and rules
  (`PUT /api/tasks/tasks/{id}/schedule`, `POST /api/rules[/{id}]`,
  `POST /api/rules/preview` with `per_page` <= 100) need the admin session
  cookie `access_token`. Task cron runs in CET.
- **Reclaimerr rule trees are nested.** Render the groups before judging a
  rule (flattening made the 90-day rules look contradictory) and preview before
  saving. Nothing without a Seerr request or the AniList tag is ever cleaned:
  the user chose this.
- **Jellyfin schedules** are set through
  `GET/POST http://192.168.1.13:8096/ScheduledTasks[/<id>/Triggers]` with
  `Authorization: MediaBrowser Token="<key>"`. A POST replaces the whole trigger
  list (keep `MaxRuntimeTicks` and the StartupTrigger); 1 h is
  `36000000000` ticks. Unverified whether triggers fire in CET or UTC. All
  libraries set `SaveLocalMetadata` and `SaveSubtitlesWithMedia`, so those tasks
  write to the HDD pool.
- **Jellyfin hardware transcoding** shows in the first line of
  `/mnt/nvme-pool/apps/jellyfin/log/FFmpeg.Transcode-*.log` on mars
  (`-hwaccel vaapi`, `scale_vaapi`, `h264_vaapi` on `/dev/dri/renderD128` is the
  full GPU path). ffmpeg only runs while transcoding.

### Telemetry

Nothing reports to stats.grafana.org: Alloy runs with `--disable-reporting`
(`modules/nixos/alloy.nix`, every NixOS host), Loki sets
`analytics.reporting_enabled = false` (`monitoring.nix`), and the NixOS Grafana
module already defaults it to false. `check_for_updates` and
`check_for_plugin_updates` stay on.

## Changelog

High-level, newest first. Details live in `git log -- hosts/mars/deimos`.

- 2026-11-23: **immich-power-tools removed** (container, route `power-tools.immich.deimos`, Gatus check, sops key, proxy IP `172.30.0.140` freed; data dir and image deleted by hand). Alloy and Loki no longer send usage reports to stats.grafana.org. Host and instance labels on logs, node and cAdvisor metrics are now the short `deimos` (were `deimos.mars.lukashirsch.de`), matching the service scrapes.
- 2026-11: **Observability cleanup** (server role `modules/nixos/server.nix`, shared by mercury, deimos and phobos; `modules/nixos/alloy.nix`). Alloy runs from `/etc/alloy/*.alloy` files on the upstream service, as root (state dir moves from `/var/lib/private/alloy` to `/var/lib/alloy`), reads container logs from the journal and scrapes cAdvisor. Prometheus keeps only its remote-write receiver: Alloy pushes every target with its former `job` and `instance`, and the node series carry `job="node"` (was `integrations/unix`, so re-pick the job in the Grafana node dashboard once). Traefik and Gatus listen on `127.0.0.1`. Routes moved to `services.traefik.routes`, the pinned IPs to per-file `let` bindings (no `proxyIps` registry), the Omada route to `stacks/omada.nix`. Its Gatus skips phobos's checks (phobos's skips deimos's), since they cannot reach each other over wg0.
- 2026-11: **Native Traefik, Grafana, Loki, Prometheus, graphite-exporter and Gatus** (`modules/nixos/traefik.nix`, `modules/nixos/gatus.nix`, host files `traefik.nix` and `monitoring.nix`; `stacks/` keeps only containers, InfluxDB and Scrutiny in `stacks/scrutiny.nix`). Routes now live next to each container (`homelab.traefik.routes` then, `services.traefik.routes` now), and every `proxy` container has a pinned address. Gatus state and the ACME store were copied once to `/var/lib/gatus` and `/var/lib/traefik`; the one-time copy scripts are removed. The old container dirs (`/mnt/nvme-pool/apps/traefik`, `/mnt/nvme-pool/apps/gatus`) stay until deleted by hand.
- 2026-11-17: `facter.json` regenerated; wg0 secrets owned by root and
  restart `wg-quick-wg0` on rotation.
- 2026-11-15: Every web UI served through Traefik over HTTPS (no host ports);
  Scrutiny collectors on mars repointed on 2026-11-17.
- 2026-10-04: **Metrics pipeline**: Alloy pushes node metrics (all Alloy hosts) to Prometheus; Prometheus scrapes Traefik, blocky (`:4000`), Grafana, Loki, InfluxDB, Gatus and mercury's Authelia/NetBird/CrowdSec over wg0; Grafana dashboards Node Exporter Full (1860), Traefik (17346), Blocky (13768), Gatus. Pull replaced by push in the 2026-11 observability cleanup above.
- 2026-10-04: **Gatus added** (`stacks/monitoring.nix`), cross-watching mercury.
- 2026-10-04: **Mealie moved here from mercury** (`stacks/mealie.nix`).
- 2026-09: Media stack extended.
- 2026-06: Upgraded to NixOS 26.05.
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
