# mercury

mercury is the public edge VPS for this fleet.

- Public ingress node
- WireGuard backbone gateway (wg0)
- NetBird control-plane node
- Identity edge (Authelia + LLDAP)
- Private DNS endpoint (Blocky)

## Hosting

- Provider: netcup
- 2 vCPU / 2 GB RAM / 60 GB SSD
- 1 GBit/s uplink (provider may throttle sustained average traffic)

## Public Surface

| Port | Proto | Component | Purpose |
| --- | --- | --- | --- |
| 80 | TCP | Traefik | HTTP -> HTTPS redirect and ACME handling |
| 443 | TCP | Traefik | TLS ingress for apps, OIDC, NetBird HTTP/gRPC |
| 8883 | TCP | Traefik | MQTTS (TLS termination) for the ldr-connect broker |
| 3478 | UDP | NetBird | STUN/TURN |
| 51820 | UDP | NetBird proxy | Embedded WireGuard peer for NetBird-only private services |
| 51821 | UDP | wg0 | Backbone VPN entrypoint |

Notes:

- Blocky DNS (53/tcp+udp) is intended for VPN/internal clients.
- SSH is intended over VPN paths.

## Network Model

| Network | Purpose | Members |
| --- | --- | --- |
| proxy | Ingress/routing plane (every member has a pinned address, kept in a `let` of its feature file and used for both the network pin and the route URL; native Traefik reaches them from the bridge address `172.30.0.1`) | Authelia, LLDAP UI, NetBird server/dashboard/proxy, Vaultwarden, SearXNG, ical-feuerwehr, Mosquitto (ldr-connect) |
| id | Identity-only traffic | LLDAP, Authelia |
| netbird | NetBird internal traffic | NetBird server, NetBird dashboard, NetBird proxy, CrowdSec |

## Services

| Service | Role | Exposure |
| --- | --- | --- |
| Traefik | Reverse proxy + TLS (native NixOS service, state in `/var/lib/traefik`) | Public 80/443 |
| Blocky | DNS for VPN/internal clients | Private 53/tcp+udp |
| LLDAP | LDAP directory | Internal; UI routed via Traefik host rule |
| Authelia | Auth portal + OIDC provider | Routed via Traefik |
| NetBird server/dashboard | Overlay VPN control plane | Routed via Traefik + 3478/udp |
| Vaultwarden | Password manager | Public via Traefik on 443 |
| SearXNG | Metasearch engine | Public via Traefik on 443 (Authelia forward-auth) |
| Mosquitto (ldr-connect) | MQTT broker for ldr-connect | MQTTS via Traefik TCP/SNI on 8883 |
| ical-feuerwehr | Calendar feed (simple-ical-server) | Public via Traefik on 443 |
| Gatus | Uptime dashboard (native NixOS service as `apps`, state in `/var/lib/gatus`; checks mercury, deimos and phobos, OIDC via Authelia) | `gatus.mercury.lukashirsch.de` via Traefik, listens on `127.0.0.1:8081` |
| Alloy | Pushes the journal (with container logs), host and cAdvisor metrics and the scrapes of Traefik, Blocky, Authelia, NetBird, CrowdSec and Gatus to Loki and Prometheus on deimos; runs as root (server role) | None (outbound only) |
| CrowdSec | IP-reputation engine; LAPI for the NetBird proxy bouncer | Internal only (netbird network) |

## Current Routing Notes

- Traefik is native (`modules/nixos/traefik.nix`): its config is built from Nix
  and it does no container discovery. Each feature file declares its routes in
  `services.traefik.routes` next to its container. Traefik restarts on every
  route change (no reload).
- `stacks/` holds only Podman containers. Native host settings live in
  `traefik.nix` (entry points, ACME env, allowlist) and `monitoring.nix`
  (Gatus); the `proxy` network is in `stacks/default.nix`.
- LLDAP uses host-based routing on lldap.mercury.lukashirsch.de.
- Vaultwarden currently routes on both:
  - vaultwarden.mars.lukashirsch.de
  - vaultwarden.mercury.lukashirsch.de
- Vaultwarden is intended to be publicly reachable via Traefik over HTTPS (not VPN-only).
- Vaultwarden is currently not behind Authelia forward-auth (intentional for now).
- SearXNG is behind Authelia forward-auth (the `authelia` Traefik middleware,
  defined in `authelia.nix` through `services.traefik.dynamicConfigOptions`) since it has no
  native OIDC support.
- Traefik dashboard route exists and is restricted with an IP allowlist middleware.
- ldr-connect broker: MQTTS on 8883 via Traefik TCP router (HostSNI on
  broker.ldr-connect.lukashirsch.de and
  broker.ldr-connect.mercury.lukashirsch.de, TLS terminated at Traefik,
  Let's Encrypt via DNS-01). The names remain manual DNS-only A records at
  Cloudflare → 5.45.99.133. Clients must use TLS with SNI; plaintext 1883
  is no longer exposed.
- NetBird peer session expiration (default 24h) is management-DB state, not
  Nix: Dashboard → Settings → Authentication. SSO-enrolled peers expire and
  must re-login ("peer login has expired" in netbird-server logs); mercury's
  own setup-key peer (`vpn.nix`) does not.

## Architecture

```text
Internet
  -> 80/443 -> Traefik
      -> auth.lukashirsch.de (Authelia)
      -> netbird.lukashirsch.de (NetBird)
      -> vaultwarden.*.lukashirsch.de (Vaultwarden, public)
      -> searxng.mercury.lukashirsch.de (SearXNG, Authelia forward-auth)
      -> lldap.mercury.lukashirsch.de (LLDAP UI)
      -> calendar.ffw-freitelsdorf.*.lukashirsch.de (ical-feuerwehr)

Identity plane
  Authelia <-> LLDAP   (id)

NetBird plane
  NetBird server <-> dashboard <-> reverse-proxy <-> CrowdSec   (netbird)

Routing plane
  Traefik + routed services   (proxy)

Backbone/admin plane
  WireGuard wg0 (10.10.1.1)
```

## Runtime Policy

- Services are managed as Podman quadlets via NixOS, except Traefik, Gatus and Alloy, which are plain NixOS services.
- Metrics are push-only: each service declares its scrape as an `/etc/alloy/<name>.alloy` file next to itself (explicit `instance = "mercury"`), and Prometheus on deimos only receives remote-write. Traefik and Gatus listen on `127.0.0.1`; the other metrics ports keep their `10.10.1.1` bind and are scraped locally by Alloy.
- All containers use `autoUpdate = "registry"` except CrowdSec (pinned, manual bumps).
- All service units use Restart = "always".

## Identity and Access Flow

1. User opens NetBird dashboard.
2. NetBird delegates auth to Authelia (OIDC).
3. Authelia authenticates against LLDAP.
4. NetBird receives OIDC tokens and continues session.

## Operational Intent

- Keep wg0 small and admin-focused.
- Use NetBird as the day-to-day user/device access plane.
- Keep the public edge narrow: Traefik (including public Vaultwarden) + required VPN ports only.

## Deploy

From `lkshrsch-workstation` (x86_64-linux, builds locally):

```bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --target-host root@10.10.1.1
```

From macOS (builds on mercury):

```bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --build-host root@mercury.lukashirsch.de --target-host root@mercury.lukashirsch.de
```

## Changelog

High-level, newest first. Details live in `git log -- hosts/mercury`.

- 2026-11: **Observability cleanup** (server role `modules/nixos/server.nix`, shared by mercury, deimos and phobos; `modules/nixos/alloy.nix`). Alloy runs from `/etc/alloy/*.alloy` files on the upstream service, as root, reads container logs from the journal (`CONTAINER_NAME`, no longer the Podman socket) and scrapes cAdvisor; every scrape is pushed to Prometheus on deimos, which no longer pulls. The node series have `job="node"` (was `integrations/unix`). Traefik and Gatus listen on `127.0.0.1` (were `10.10.1.1`). Routes moved to `services.traefik.routes` with the pinned IPs in per-file `let` bindings (the `proxyIps` registry and its assertion are gone). Gatus also checks phobos, and the Authelia `gatus` client accepts phobos's callback URL.
- 2026-11: **Native Traefik and Gatus** (`modules/nixos/traefik.nix`, `modules/nixos/gatus.nix`). Traefik's ACME state is seeded once from `/root/stacks/traefik/letsencrypt` into `/var/lib/traefik`; Gatus data is copied once from `/root/stacks/gatus/data` into `/var/lib/gatus`. Both copies ran; the one-time scripts are removed, and the old files stay until deleted by hand.
- 2026-10-04: **Metrics published on wg0 only** (`10.10.1.1`) for Prometheus on deimos: Traefik `:8082`, blocky `:4000`, Authelia `:9959`, NetBird `:9090`, CrowdSec `:6060`, Gatus `:8081`. Host metrics are pushed by Alloy. Superseded by the 2026-11 observability cleanup above.
- 2026-10-04: **Gatus added** (`stacks/monitoring.nix`); shared module `modules/nixos/gatus.nix`.
- 2026-10-04: NetBird images pinned; CrowdSec WAL enabled.
- 2026-10-04: **Mealie moved to deimos** (`mealie.deimos.mars.lukashirsch.de`).
  Old `mealie.mercury` route dropped; Authelia OIDC redirect URI updated.
  Mercury keeps only the identity/edge workloads.
- 2026-09-28: Authelia OIDC clients remember consent; refresh-token lifespan
  extended.
- 2026-08/09: Repo moved to the Dendritic layout; shared modules refactored.
- 2026-04-09: Mercury declared as a flake-parts host (Traefik, Authelia,
  LLDAP, CrowdSec, Vaultwarden, SearXNG, NetBird, ical-feuerwehr, ldr-connect
  broker).
