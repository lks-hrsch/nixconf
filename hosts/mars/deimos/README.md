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

## Changelog

High-level, newest first. Details live in `git log -- hosts/mars/deimos`.

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
