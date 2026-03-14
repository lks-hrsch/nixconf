# mercury — Ubuntu to NixOS Migration

This runbook migrates mercury from the current Ubuntu 24.04 Docker host to the new NixOS definition in this repository. Follow the steps chronologically. Do not skip ahead — each step has a clear checkpoint before you move on.

---

## 0. Pre-Requisites (on your workstation)

Before touching the server:

- [ ] You have console access through the netcup panel so you can recover from a broken SSH or network state.
- [ ] `nixos-anywhere` is available: `nix shell github:nix-community/nixos-anywhere`.
- [ ] The flake in this repo evaluates cleanly: `nix flake check path:$PWD`.
- [ ] You have committed `hosts/mercury/_hardware-configuration.nix` **or** `hosts/mercury/facter.nix` (see step 3).
- [ ] Your SOPS age key is available at `~/.config/sops/age/keys.txt`.

---

## 1. Back Up the Running Ubuntu Host

SSH in and run:

```bash
mkdir -p /root/mercury-backup

# WireGuard private config (contains the server private key)
cp /etc/wireguard/wg0.conf /root/mercury-backup/wg0.conf

# All running stacks
tar czf /root/mercury-backup/stacks.tgz /root/stacks

# Container inventory
docker ps -a  > /root/mercury-backup/docker-ps.txt
docker volume ls > /root/mercury-backup/docker-volumes.txt

# IMPORTANT: the command above only lists volume names, it does NOT back up
# volume content. Export every volume into its own archive.
mkdir -p /root/mercury-backup/volumes
for v in $(docker volume ls -q); do
  echo "Backing up volume: $v"
  docker run --rm \
    -v "$v":/volume:ro \
    -v /root/mercury-backup/volumes:/backup \
    busybox \
    sh -c "tar -czf /backup/backup-of-${v}.tar.gz -C /volume ."
done
```

The `backup-of-<volume>.tar.gz` naming is compatible with
`_before-migration/restore-docker-volumes.sh`.

Copy everything off the box to your workstation before proceeding:

```bash
scp -r root@mercury.lukashirsch.de:/root/mercury-backup ./hosts/mercury/_backup
```

---

## 2. Capture and Extract Secrets From the Current Host

The new NixOS modules read runtime secrets from `/var/lib/mercury/secrets/`. You must convert the current Ubuntu files into that layout **before** the final install.

### WireGuard private key

From `wg0.conf` (the `PrivateKey =` line under `[Interface]`):

```bash
# store locally — will be placed on NixOS in step 5
echo "cCW8lzh8gGnKTPEQi+wPYKPirX8sT1j/RA4Bls4w/X8=" > ~/mercury-wg0-private-key
```

### WireGuard preshared keys

Extract the `PresharedKey =` value for each peer from `wg0.conf` and write one file per peer. Name them to match what `vpn.nix` references:

```
earth
phobos
deimos
homeassistant-freitelsdorf
homeassistant-dresden-florain
lkshrsch-workstation-nixos
florian-mbp
mberger-mbp
mschuett-win
mberger-iphone
mschuett-tablett
```

Peers that have no `PresharedKey =` line (mbp-m3, iPad, iPhone, megan) need no file; their entries in `vpn.nix` omit `presharedKeyFile`.

### Application secret files

Collect the following into a local staging area (`~/mercury-stage/`):

| Target path on NixOS | Source |
| --- | --- |
| `/var/lib/mercury/netbird/config.yaml` | `_before-migration/netbid-config.yaml` with one edit: change `auth.issuer` from `https://netbird.lukashirsch.de/oauth2` to `https://auth.lukashirsch.de` |
| `/var/lib/mercury/netbird/dashboard.env` | `_before-migration/netbird-dashboard.env` with edits: set `AUTH_AUTHORITY=https://auth.lukashirsch.de`, `AUTH_CLIENT_ID=netbird-dashboard`, `AUTH_CLIENT_SECRET=<secret you generate>` |
| `/var/lib/mercury/vaultwarden/vaultwarden.env` | `_before-migration/vaultwarden-stack.env` (keep as-is, just rename) |
| `/var/lib/mercury/authelia/configuration.yml` | New file (see note below) |
| `/var/lib/mercury/lldap/lldap.env` | New file (see note below) |

**LLDAP** is new infrastructure. Create `/var/lib/mercury/lldap/lldap.env` with at minimum:

```env
LLDAP_JWT_SECRET=<generate with: openssl rand -base64 32>
LLDAP_LDAP_USER_PASS=<your admin password>
LLDAP_LDAP_BASE_DN=dc=lukashirsch,dc=de
LLDAP_HTTP_PORT=17170
LLDAP_LDAP_PORT=3890
```

**Authelia** is also new. Create `/var/lib/mercury/authelia/configuration.yml` with an LDAP backend pointing at `lldap:3890`, session secrets, storage, and an OIDC client block for `netbird-dashboard`. Refer to the official Authelia configuration docs; a skeleton is provided in the [Authelia docs](https://www.authelia.com/configuration/miscellaneous/introduction/).

---

## 3. Generate a Hardware Module

Boot the server into a NixOS installer image (using the netcup rescue or a custom ISO), then run one of the following from your workstation:

### Option A — plain hardware config

```bash
# from the installer running on mercury
nixos-generate-config --no-filesystems --root /
# copy /etc/nixos/hardware-configuration.nix back to workstation
scp root@<installer-ip>:/etc/nixos/hardware-configuration.nix \
  hosts/mercury/_hardware-configuration.nix
```

### Option B — nixos-facter

```bash
nix run github:nix-community/nixos-facter -- \
  --host root@<installer-ip> \
  --output hosts/mercury/facter.nix
```

Commit the file before proceeding. The optional import in `configuration.nix` picks it up automatically.

---

## 4. Stage the Runtime Files via nixos-anywhere `--extra-files`

`nixos-anywhere` accepts an `--extra-files` overlay directory that gets copied verbatim onto the new system. Prepare it locally:

```bash
mkdir -p ~/mercury-extra/var/lib/mercury/secrets/wg0/preshared-keys
mkdir -p ~/mercury-extra/var/lib/mercury/netbird
mkdir -p ~/mercury-extra/var/lib/mercury/authelia
mkdir -p ~/mercury-extra/var/lib/mercury/lldap
mkdir -p ~/mercury-extra/var/lib/mercury/vaultwarden/data
mkdir -p ~/mercury-extra/var/lib/mercury/traefik/letsencrypt
mkdir -p ~/mercury-extra/etc/sops/age

# WireGuard keys
cp ~/mercury-wg0-private-key \
  ~/mercury-extra/var/lib/mercury/secrets/wg0/private-key
# repeat for every preshared-key file:
cp ~/mercury-stage/psk-earth \
  ~/mercury-extra/var/lib/mercury/secrets/wg0/preshared-keys/earth
# ... and so on for all peers

# Application secrets
cp ~/mercury-stage/authelia-configuration.yml \
  ~/mercury-extra/var/lib/mercury/authelia/configuration.yml
cp ~/mercury-stage/lldap.env \
  ~/mercury-extra/var/lib/mercury/lldap/lldap.env
cp ~/mercury-stage/netbird-config.yaml \
  ~/mercury-extra/var/lib/mercury/netbird/config.yaml
cp ~/mercury-stage/netbird-dashboard.env \
  ~/mercury-extra/var/lib/mercury/netbird/dashboard.env
cp ~/mercury-stage/vaultwarden.env \
  ~/mercury-extra/var/lib/mercury/vaultwarden/vaultwarden.env

# Vaultwarden data (migrate from Ubuntu backup)
rsync -a ~/mercury-backup-stacks/vaultwarden/data/ \
  ~/mercury-extra/var/lib/mercury/vaultwarden/data/

# SOPS age key so secrets.yaml is decryptable on the new host
cp ~/.config/sops/age/keys.txt \
  ~/mercury-extra/etc/sops/age/keys.txt

# Lock down permissions on secrets
chmod 700 ~/mercury-extra/var/lib/mercury/secrets
chmod 600 ~/mercury-extra/var/lib/mercury/secrets/wg0/private-key
chmod 600 ~/mercury-extra/var/lib/mercury/secrets/wg0/preshared-keys/*
chmod 600 ~/mercury-extra/etc/sops/age/keys.txt
```

---

## 5. Install NixOS With nixos-anywhere

With the installer still running on the server (and your `~/mercury-extra` staged):

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#mercury \
  --extra-files ~/mercury-extra \
  root@<installer-ip>
```

`nixos-anywhere` will partition the disk, install the closures, copy your extra files, and reboot. Watch for the reboot; the server should come back on the same public IP.

If you want to use `nixos-facter` as part of the install pass, add `--generate-hardware-config nixos-facter hosts/mercury/facter.nix` to the command instead of the manual step 3B above.

---

## 6. First Boot Verification

Use the netcup console first, not SSH, until you confirm `wg0` is up.

```bash
# network
ip addr
ip route

# WireGuard
systemctl status wg-quick-wg0.service
wg show

# Podman / quadlets
podman ps -a
systemctl status traefik.service blocky.service lldap.service \
  authelia.service netbird-server.service netbird-dashboard.service \
  vaultwarden.service
```

If `wg0` is up, switch to VPN-based SSH on `10.10.1.1`.

---

## 7. Service Startup Order

The quadlets have explicit `After=` / `Requires=` wiring, but on first boot you may need to seed LLDAP and Authelia before NetBird starts. Recommended sequence:

1. Confirm `traefik` is healthy: `podman logs traefik`
2. Confirm `blocky` is healthy: `dig @10.10.1.1 mercury.lukashirsch.de`
3. Bring up `lldap`: `systemctl start lldap.service`
   - Create admin account and default groups via the LLDAP web UI on `http://10.10.1.1:17170`.
4. Bring up `authelia`: `systemctl start authelia.service`
   - Verify `https://auth.lukashirsch.de/.well-known/openid-configuration` resolves through Traefik.
5. Start `netbird-server` and `netbird-dashboard`.
6. Verify `vaultwarden` serves `https://vaultwarden.mars.lukashirsch.de`.

---

## 8. External Behaviour Checklist

- [ ] `dig @10.10.1.1 mercury.lukashirsch.de` returns `10.10.1.1`
- [ ] `https://auth.lukashirsch.de` loads the Authelia portal
- [ ] `https://netbird.lukashirsch.de` loads the NetBird dashboard
- [ ] NetBird mobile/desktop client connects and authenticates via Authelia OIDC
- [ ] `https://vaultwarden.mars.lukashirsch.de` loads the Vaultwarden vault
- [ ] WireGuard peers (deimos, phobos, workstation-nixos, …) re-connect and reach `10.10.1.1`

---

## 9. Post-Migration Hardening

Once the stack is stable:

1. **Move WireGuard keys into SOPS.** Add a `wireguard-mercury.yaml` sops file and add a `mercury` branch to `modules/sops.nix`, then update `vpn.nix` to reference `config.sops.secrets.*` paths instead of the plain `/var/lib/mercury/secrets` files.
2. **Pin image versions.** Replace `latest` tags in `stacks/authelia.nix`, `stacks/netbird.nix`, and `stacks/vaultwarden.nix` with explicit version digests once you have confirmed the stack is healthy.
3. **Authelia forward-auth.** Consider protecting Vaultwarden with an Authelia forward-auth middleware in Traefik rather than exposing it directly.
4. **Restrict SSH.** Once `wg0` is stable, restrict the public firewall so SSH is not reachable from the internet at all (`networking.firewall.allowedTCPPorts` already excludes port 22 from the public list; `openssh.listenAddresses` in `configuration.nix` limits it to the WireGuard interface).
