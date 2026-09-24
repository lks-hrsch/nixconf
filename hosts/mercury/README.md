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
| proxy | Ingress/routing plane | Traefik, Authelia, LLDAP UI, NetBird server/dashboard/proxy, Vaultwarden, SearXNG, Mealie, ical-feuerwehr, Mosquitto (ldr-connect) |
| id | Identity-only traffic | LLDAP, Authelia |
| netbird | NetBird internal traffic | NetBird server, NetBird dashboard, NetBird proxy, CrowdSec |

## Services

| Service | Role | Exposure |
| --- | --- | --- |
| Traefik | Reverse proxy + TLS | Public 80/443 |
| Blocky | DNS for VPN/internal clients | Private 53/tcp+udp |
| LLDAP | LDAP directory | Internal; UI routed via Traefik host rule |
| Authelia | Auth portal + OIDC provider | Routed via Traefik |
| NetBird server/dashboard | Overlay VPN control plane | Routed via Traefik + 3478/udp |
| Vaultwarden | Password manager | Public via Traefik on 443 |
| SearXNG | Metasearch engine | Public via Traefik on 443 (Authelia forward-auth) |
| Mosquitto (ldr-connect) | MQTT broker for ldr-connect | MQTTS via Traefik TCP/SNI on 8883 |
| Mealie | Recipe manager (OIDC via Authelia) | Public via Traefik on 443 |
| ical-feuerwehr | Calendar feed (simple-ical-server) | Public via Traefik on 443 |
| CrowdSec | IP-reputation engine; LAPI for the NetBird proxy bouncer | Internal only (netbird network) |

## Current Routing Notes

- LLDAP uses host-based routing on lldap.mercury.lukashirsch.de.
- Vaultwarden currently routes on both:
  - vaultwarden.mars.lukashirsch.de
  - vaultwarden.mercury.lukashirsch.de
- Vaultwarden is intended to be publicly reachable via Traefik over HTTPS (not VPN-only).
- Vaultwarden is currently not behind Authelia forward-auth (intentional for now).
- SearXNG is behind Authelia forward-auth (the `authelia@file` Traefik middleware,
  defined in `traefik.nix`'s dynamic config) since it has no native OIDC support.
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
      -> mealie.mercury.lukashirsch.de (Mealie)
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

- Services are managed as Podman quadlets via NixOS.
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
