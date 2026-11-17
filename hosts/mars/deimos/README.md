# deimos

deimos is the application LXC on the `mars` TrueNAS box. It runs most
self-hosted workloads as Podman quadlets (media, photos, AI, monitoring,
smart home, network controller).

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

- Traefik owns 80/443 and discovers containers via Podman labels on the
  `proxy` network (`172.30.0.0/24`). Certificates: Let's Encrypt DNS-01 via
  Cloudflare.
- Hostnames follow `<app>.deimos.mars.lukashirsch.de`. Blocky on deimos and on
  mercury resolves them to `10.10.1.18` for VPN clients; `ddns-updater` keeps
  the public `mars` / `*.mars` records current.
- SSO: apps with OIDC use Authelia on mercury. Jellyfin authenticates through
  the Authelia HTTP API plugin instead of OIDC.
- Firewall ports are listed in `stacks/default.nix`.

## Services

| Stack file | Services |
| :--- | :--- |
| `stacks/traefik.nix` | Traefik (+ `proxy` network) |
| `stacks/blocky.nix` | Blocky DNS |
| `stacks/ddns-updater.nix` | DDNS updater |
| `stacks/media.nix` | Jellyfin and the media automation stack (own `media` network, Gluetun VPN egress) |
| `stacks/immich.nix` | Immich (server, ML, Valkey, Postgres), Immich Power Tools |
| `stacks/ai.nix` | Open WebUI, LiteLLM |
| `stacks/mealie.nix` | Mealie (recipes, OIDC via Authelia) |
| `stacks/monitoring.nix` | Grafana, Loki, Prometheus (pull jobs + remote-write receiver at `prometheus.deimos…`, basic auth shared with Loki), InfluxDB, Scrutiny |
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

## Changelog

High-level, newest first. Details live in `git log -- hosts/mars/deimos`.

- 2026-11-17: `facter.json` regenerated; wg0 secrets owned by root and
  restart `wg-quick-wg0` on rotation.
- 2026-11-15: Every web UI served through Traefik over HTTPS (no host ports);
  Scrutiny collectors on mars repointed on 2026-11-17.
- 2026-10-04: **Metrics pipeline**: Alloy pushes node metrics (all Alloy hosts) to Prometheus; Prometheus scrapes Traefik, blocky (`:4000`), Grafana, Loki, InfluxDB, Gatus and mercury's Authelia/NetBird/CrowdSec over wg0; Grafana dashboards Node Exporter Full (1860), Traefik (17346), Blocky (13768), Gatus.
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
