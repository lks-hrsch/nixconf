# mercury

mercury is the public edge server in this fleet. It is hosted at netcup and acts as the main ingress node, identity edge, and VPN gateway for the private environment.

It is designed as a NixOS machine with services managed declaratively and deployed as Podman quadlets.

## Role

- Public VPS and edge entrypoint
- Main reverse proxy for internet-facing services
- Entry point to the classic WireGuard backbone network
- Entry point to the NetBird WireGuard-based overlay network
- NetBird control plane host
- OIDC provider host for internal services and NetBird sign-in
- DNS endpoint for VPN-connected clients

## Hosting

- Provider: netcup
- CPU: 2 vCores
- Memory: 2 GB RAM
- Storage: 60 GB SSD
- Network: 1 GBit/s
- Traffic policy: traffic may be throttled to `100 MBit/s` if the 24-hour average exceeds that limit

## Network Topology

mercury is the external network anchor for two parallel VPN models.

```text
Internet
  -> 80/tcp     Traefik HTTP redirect and ACME handling
  -> 443/tcp    Traefik HTTPS, OIDC, NetBird API/gRPC, application ingress
  -> 3478/udp   NetBird STUN/TURN
  -> 51821/udp  WireGuard backbone

Administrative backbone (wg0)
  -> 10.10.1.1 mercury
  -> server administration
  -> host-to-host operational access

NetBird overlay
  -> user and device access across sites
  -> service-to-service overlay connectivity
  -> identity-aware access via Authelia OIDC
```

The classic `wg0` network exists as the low-level backbone. Its long-term purpose is administrative access, bootstrap connectivity, and direct operational reachability between infrastructure nodes.

The NetBird network is the higher-level access plane. It is also WireGuard-based, but it adds coordination, relay, NAT traversal, policy management, and identity-driven user access. The intended direction is that normal user and device access moves to NetBird, while `wg0` remains a smaller administrative network.

## Open Ports

The target firewall policy for mercury is:

| Service | Port(s) | Protocol | Exposure | Reason |
| --- | --- | --- | --- | --- |
| Traefik | `80` | TCP | Public | HTTP redirect and ACME HTTP-01 validation when used |
| Traefik | `443` | TCP | Public | HTTPS ingress for applications, Authelia, and NetBird HTTP/gRPC traffic |
| Blocky | `53` | TCP/UDP | Private only | DNS for `wg0` and NetBird-connected clients |
| SSH | `22` | TCP | Admin only | Server administration, restricted to VPN and trusted internal paths |
| WireGuard backbone | `51821` | UDP | Public | Entrypoint for the classic `wg0` backbone network |
| NetBird | `443` | TCP | Public | Dashboard, management API/gRPC, signal gRPC, and relay WebSocket behind Traefik |
| NetBird | `3478` | UDP | Public | STUN/TURN for NAT traversal and peer connectivity |

Notes:

- Blocky should not be exposed on the public internet.
- SSH should not be a generally public management port; it should be reachable through `wg0` or another trusted administrative path.
- NetBird does not need a separate public WireGuard listener in the same style as the classic backbone. Its public entrypoints are primarily `443/tcp` and `3478/udp`.

## Service Model

mercury runs its application stack as Podman quadlets managed by NixOS. Each service is defined declaratively, started by systemd, and updated through the normal NixOS deployment flow.

Core characteristics:

- NixOS is the single source of truth for system and service configuration
- Podman provides the container runtime
- Quadlets map containers, networks, volumes, and dependencies into native systemd units
- Secrets are injected through the repository's secret-management flow
- Service restarts, ordering, and lifecycle are handled through systemd and quadlet definitions

## Container Networks

The quadlet stack is segmented into three Podman bridge networks:

| Network | Purpose | Typical Members |
| --- | --- | --- |
| `mercury-reverse-proxy` | Shared ingress and HTTP service discovery for Traefik | Traefik, Authelia, LLDAP UI, NetBird API/dashboard, Vaultwarden |
| `mercury-id` | Identity-plane traffic only | LLDAP, Authelia |
| `mercury-netbird` | Private internal network for NetBird components | NetBird server and dashboard |

Why this split:

- Traefik discovers and routes only services reachable on `mercury-reverse-proxy`.
- Identity backends stay isolated from general service traffic.
- Service internal traffic can be separated from identity-plane internals.

Prefixing network names with `mercury-` is intentional and recommended because:

- It avoids ambiguous names when multiple hosts run Podman on similar stacks.
- It reduces accidental cross-host copy/paste mistakes in labels and network references.
- It makes operational inspection (`podman network ls`, logs, troubleshooting) clearer.

## Quadlet Stack

| Service | Purpose | Exposure | Runtime |
| --- | --- | --- | --- |
| Traefik | Edge reverse proxy, TLS termination, and service routing | Public `80/tcp`, `443/tcp` | Podman quadlet |
| NetBird | VPN coordination, relay, and management plane authenticated through Authelia OIDC | Public `443/tcp`, `3478/udp` | Podman quadlet |
| LLDAP | Lightweight LDAP directory for identities and groups | Internal only | Podman quadlet |
| Authelia | Authentication portal, OIDC provider, and access control | Behind Traefik | Podman quadlet |
| Vaultwarden | Password manager | Behind Traefik | Podman quadlet |
| Blocky | DNS for backbone and NetBird-connected clients | Private `53/tcp`, `53/udp` | Podman quadlet |

## Architecture

```text
Internet
  -> Traefik
      -> Authelia
      -> NetBird dashboard and API
      -> Vaultwarden

Identity layer
  Authelia <-> LLDAP
  NetBird <-> Authelia via generic OIDC

Container networks
  mercury-reverse-proxy: Traefik and routed HTTP services
  mercury-id: LLDAP and Authelia internal identity traffic
  mercury-netbird: NetBird internal service traffic

Administrative network
  Operators <-> WireGuard backbone (wg0) <-> mercury <-> internal hosts

Overlay network
  Users and devices <-> NetBird

Infrastructure services
  wg0 clients -> Blocky
  NetBird clients -> Blocky
```

The architecture is intentionally layered.

1. Edge layer.
Traefik is the single public HTTP(S) edge. It terminates TLS, applies routing and middleware policy, and keeps application containers off the public network surface.

2. Identity layer.
LLDAP stores users and groups. Authelia consumes that directory, handles authentication and authorization, and exposes OIDC for services that need delegated sign-in.

3. Network access layer.
mercury exposes both the classic WireGuard backbone and the NetBird overlay. The backbone is the low-level administrative network. NetBird is the user-facing and device-facing access network built on WireGuard with higher-level coordination and policy.

4. Application and platform layer.
Vaultwarden is delivered through Traefik and protected by the surrounding identity and access model. Blocky stays private and provides consistent DNS resolution across both VPN domains.

This split keeps the operational plane and the user plane separate. `wg0` remains predictable and minimal for administration, while NetBird becomes the main WireGuard-based network for day-to-day access.

## LLDAP Reverse Proxy

LLDAP is exposed behind Traefik with host-based routing (dedicated domain), not subpath routing.

- Recommended host: `lldap.lukashirsch.de`
- Traefik router target: LLDAP HTTP UI on port `17170`
- LDAP protocol port `3890` remains internal and is not internet-facing

This matches LLDAP's guidance and community discussions: dedicated host-based reverse proxying is straightforward, while subpath deployments are intentionally not a primary supported mode.

## NetBird Authentication

NetBird uses Authelia as its external identity provider through NetBird's generic OIDC connector.

The intended flow is:

- Authelia publishes a standard OIDC issuer and discovery document through Traefik
- NetBird is registered in Authelia as a confidential OIDC client
- NetBird discovers Authelia endpoints from `/.well-known/openid-configuration`
- Users authenticate against Authelia and are redirected back to the NetBird callback URL
- NetBird validates tokens through Authelia's JWKS endpoint and provisions or updates the user

The OIDC integration should use:

- authorization code flow
- confidential client authentication with client secret
- scopes `openid`, `profile`, `email`, and optionally `groups`
- required claim `sub`
- recommended claims `email`, `name`, and optionally `preferred_username`

If JWT group sync is enabled in NetBird, Authelia should expose a `groups` claim as a JSON array of strings.

## Service Responsibilities

- Traefik is the only internet-facing HTTP entrypoint and owns routing, TLS, and middleware integration.
- NetBird provides the main WireGuard-based overlay for users and remote nodes and delegates authentication to Authelia over OIDC.
- LLDAP is the identity directory backend used by Authelia.
- Authelia protects internal applications, centralizes authentication and authorization, and acts as the OIDC provider for NetBird.
- Vaultwarden provides password management behind the shared ingress and identity setup.
- Blocky resolves internal names and provides DNS for both backbone and NetBird-connected clients.
