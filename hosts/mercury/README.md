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
| 51821 | UDP | wg0 | Backbone VPN entrypoint |

Notes:

- Blocky DNS (53/tcp+udp) is intended for VPN/internal clients.
- SSH is intended over VPN paths.

## Network Model

| Network | Purpose | Members |
| --- | --- | --- |
| mercury-reverse-proxy | Ingress/routing plane | Traefik, Authelia, LLDAP UI, NetBird, Vaultwarden, SearXNG, Mosquitto (ldr-connect) |
| mercury-id | Identity-only traffic | LLDAP, Authelia |
| mercury-netbird | NetBird internal traffic | NetBird server, NetBird dashboard |

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

## Current Routing Notes

- LLDAP uses host-based routing on lldap.lukashirsch.de.
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

## Architecture

```text
Internet
  -> 80/443 -> Traefik
      -> auth.lukashirsch.de (Authelia)
      -> netbird.lukashirsch.de (NetBird)
      -> vaultwarden.*.lukashirsch.de (Vaultwarden, public)
      -> searxng.mercury.lukashirsch.de (SearXNG, Authelia forward-auth)
      -> lldap.lukashirsch.de (LLDAP UI)

Identity plane
  Authelia <-> LLDAP   (mercury-id)

NetBird plane
  NetBird server <-> NetBird dashboard   (mercury-netbird)

Routing plane
  Traefik + routed services   (mercury-reverse-proxy)

Backbone/admin plane
  WireGuard wg0 (10.10.1.1)
```

## Runtime Policy

- Services are managed as Podman quadlets via NixOS.
- All containers are configured with autoUpdate = "registry".
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

## deploy config

via darwin

``` bash
❯ nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --build-host root@mercury.lukashirsch.de --target-host root@mercury.lukashirsch.de
```
