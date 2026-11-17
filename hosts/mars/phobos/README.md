# phobos

phobos is the VPN-connected LXC on the `mars` TrueNAS box. It has direct
access to the `pool/datasets` dataset and hosts the `openvad` user's
workloads (Podman available, no quadlet stacks yet).

- NixOS (x86_64) in an Incus LXC (`marsLxcBase`), LAN IP `192.168.1.12`
- wg0 backbone IP `10.10.1.17` (wg-quick, peers mercury and earth); no NetBird
- Imports `base`, `podman`, `alloy`, `marsLxcBase`

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

## Runtime policy

- Secrets: wg0 keys from `secrets/wireguard-phobos.yaml` (sops-nix, root-owned,
  rotation restarts `wg-quick-wg0`).
- Monitoring: Alloy ships logs and metrics with host label
  `phobos.mars.lukashirsch.de`; collectors that report host-wide or bogus
  data inside an LXC are disabled (`monitoring.nix`).
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

- 2026-11-17: `facter.json` added; `podman` and `alloy` imported; `openvad`
  user (UID 3005, DIRECT idmap). First deploy since 2025: it switched wg0
  from systemd-networkd to wg-quick (the stale `wg0` link had to be deleted
  by hand) and dbus to dbus-broker (needed an instance restart).
- 2025-12: wg0 config moved to wg-quick.
- 2025-10: WireGuard backbone across the Mars containers.
- 2025-07/08: Initial Mars LXC configuration.
