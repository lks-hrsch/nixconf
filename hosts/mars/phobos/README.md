# phobos

phobos is the VPN-connected LXC on the `mars` TrueNAS box. It has direct
access to the `pool/datasets` dataset and hosts the `openvad` user's
workloads (Podman available, no quadlet stacks yet). It is also a server like
mercury and deimos: it runs its own native Traefik (dashboard only) and Gatus.

- NixOS (x86_64) in an Incus LXC (`marsLxcBase`), LAN IP `192.168.1.12`
- wg0 backbone IP `10.10.1.17` (wg-quick, peers mercury and earth), no wg0 DNS:
  names resolve through the LAN resolver `192.168.1.1`, so deimos is reached at
  `192.168.1.13` (its wg0 IP `10.10.1.18` has no route from phobos)
- NetBird `wt0` IP `10.10.10.227`, routing peer (`useRoutingFeatures = "both"`)
- Imports `base` (which brings `alloy`), `podman`, `netbird`, `server`, `marsLxcBase`

## Hardware

phobos runs on the same `mars` host as deimos; see the
[deimos hardware table](../deimos/README.md#hardware) (Ryzen 7 7700X, 64 GB
ECC, RAIDZ2 HDD pool + NVMe mirror, 10 GbE).

### Instance limits

| Setting | Value |
| :--- | :--- |
| Memory | **18 GiB** hard limit (`memory.max`) |
| CPU | No limit; all 8 host cores |
| Autostart | Off in TrueNAS |
| Passthrough | None |

## Storage

Incus disk devices (TrueNAS → container):

| Host path | Container path |
| :--- | :--- |
| `/mnt/pool/datasets` | `/mnt/pool/datasets` |
| `/mnt/pool/datasets` | `/mnt/mars-nfs/datasets` (same dataset, second mount) |

## Users

| User | UID | Notes |
| :--- | :--- | :--- |
| `openvad` | 3005 | Normal user, group `users` (100), SSH key from `repo.constants.sshPublicKey` |

`openvad` matches the TrueNAS user of the same name, which has
`userns_idmap: DIRECT`, so files it owns on the NAS show up as `openvad`
inside phobos. Only the UID is mapped: gid 100 is not, so NAS files
group-owned by 100 appear as `nogroup`. Map the group in TrueNAS too if
group access is needed.

## Web UIs

| URL | Component | Access |
| :--- | :--- | :--- |
| `https://traefik.phobos.mars.lukashirsch.de` | Traefik dashboard | `internal-ipallowlist` (`192.168.1.0/24`, wg0 `10.10.1.0/24`, wt0 `10.10.10.0/24`) |
| `https://gatus.phobos.mars.lukashirsch.de` | Gatus | OIDC via Authelia on mercury |

- The server role (`modules/nixos/server.nix`) provides Traefik, Gatus, the
  dashboard route and the Alloy container-log and cAdvisor parts;
  `hosts/mars/phobos/stacks/server.nix` holds what is phobos-specific: the Cloudflare
  DNS-01 sops env file, the allowlist and the Gatus checks. There is no
  `monitoring.nix` host module anymore.
- Traefik opens 80/443 (LAN and wg0) and has no `proxy` network and no ACME
  seed, so it orders its two certificates (traefik and gatus hostnames) fresh
  at the first start (DNS-01, about 60 s each). Blocky on mercury and deimos
  already resolves `*.phobos.mars.lukashirsch.de`.
- Gatus listens on `127.0.0.1:8081` and checks phobos's own two UIs and
  mercury's checks, but not deimos (the two share the Incus host and skip each
  other). Mercury's Gatus checks the phobos UIs in turn.
- The dashboards are reachable over NetBird through the `mars-phobos` resource
  (`192.168.1.12/32`).

## Runtime policy

- Secrets: wg0 keys from `secrets/wireguard-phobos.yaml` (sops-nix, root-owned,
  rotation restarts `wg-quick-wg0`). Traefik and Gatus read
  `traefik/cloudflare-dns-api-token`, `traefik/email` and
  `gatus/oidc_client_secret` from `secrets/stacks-mars-phobos.yaml`; Alloy's
  Loki basic auth comes from `secrets/secrets-mars-deimos.yaml`.
- NetBird: the setup key is `netbird/setup-key` in `secrets/stacks-mars-phobos.yaml`,
  owned by `netbird-wt0`. `LoadCredential` never populates `/run/credentials` in
  this LXC, so `netbird-wt0-login` reads the sops file directly
  (`NB_SETUP_KEY_FILE`). A failed login unit is not restarted by a switch:
  `systemctl start netbird-wt0-login`.
- Monitoring: Alloy pushes logs and metrics to deimos with host label
  `phobos.mars.lukashirsch.de` (`networking.fqdn`), as root (server role),
  including container logs from the journal, cAdvisor and the Traefik and
  Gatus scrapes (`instance="phobos"`). Collectors that report host-wide or bogus
  data inside an LXC are disabled (`services.alloy.disabledCollectors` in
  `hosts/mars/lxc-base.nix`).
- Hardware config comes from `facter.json` (`nixos-facter`, generated
  2026-11-17). Regenerate with:

  ```bash
  ssh root@192.168.1.12 'nix run nixpkgs#nixos-facter -- -o /dev/stdout' > hosts/mars/phobos/facter.json
  ```

## Deploy

From `lkshrsch-workstation` (builds locally):

```bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#phobos --target-host root@192.168.1.12
```

## Operational notes

State below lives in TrueNAS, not in Nix.

### Adding a mapped user

A new TrueNAS user with `userns_idmap: DIRECT` is only mapped into phobos
after the instance restarts (the map is built at start). Check with
`grep -w <uid> /proc/self/uid_map` inside phobos. Create the NixOS user with
the same UID after the restart: its home directory cannot be chowned to an
unmapped UID.

## Changelog

High-level, newest first. Details live in `git log -- hosts/mars/phobos`.

- 2026-11: **Server role**: native Traefik dashboard and Gatus
  (`hosts/mars/phobos/stacks/server.nix`, `modules/nixos/server.nix`), secrets in
  `secrets/stacks-mars-phobos.yaml`, Alloy as root with container logs and the
  Traefik and Gatus scrapes. `monitoring.nix` is gone: Alloy is the shared
  `modules/nixos/alloy.nix`, with its LXC collector list in `lxc-base.nix`.
  Deploy mercury first or together (Authelia redirect URI for the phobos Gatus).
- 2026-11-17: `facter.json` added; `podman` and `alloy` imported; `openvad`
  user (UID 3005, DIRECT idmap). First deploy since 2025: it switched wg0
  from systemd-networkd to wg-quick (the stale `wg0` link had to be deleted
  by hand) and dbus to dbus-broker (needed an instance restart).
- 2025-12: wg0 config moved to wg-quick.
- 2025-10: WireGuard backbone across the Mars containers.
- 2025-07/08: Initial Mars LXC configuration.
