# mercury - Ubuntu to NixOS Migration

Concise operator runbook for migrating mercury to the NixOS host definition in this repo.

## Status

- [x] Step 1 backup completed (stacks, docker inventory, volume archives, wg0.conf)
- [ ] Migration install not yet completed

---

## 1. Preconditions (Workstation)

- [ ] Netcup console access is available
- [ ] `nixos-anywhere` is available
  - `nix shell github:nix-community/nixos-anywhere`
- [ ] Flake evaluates correctly
  - `nix eval .#nixosConfigurations.mercury.config.system.build.toplevel.drvPath`
- [ ] SOPS age key exists at `~/.config/sops/age/keys.txt`

---

## 2. Backup Current Ubuntu Host

Status: Already completed once; keep as re-run procedure.

```bash
mkdir -p /root/mercury-backup

cp /etc/wireguard/wg0.conf /root/mercury-backup/wg0.conf
tar czf /root/mercury-backup/stacks.tgz /root/stacks

docker ps -a > /root/mercury-backup/docker-ps.txt
docker volume ls > /root/mercury-backup/docker-volumes.txt

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

Copy the backup set to the repo:

```bash
scp -r root@mercury.lukashirsch.de:/root/mercury-backup ./hosts/mercury/_backup
```

---

## 3. Deployment and Hardware Configuration

### Prepare SOPS Activation

```bash
rm -rf "$HOME/mercury-extra"
mkdir -p "$HOME/mercury-extra/etc/sops/age"
install -m 600 "$HOME/.config/sops/age/keys.txt" "$HOME/mercury-extra/etc/sops/age/keys.txt"
```

<!-- --build-on remote \ -->
### Run Migration

```bash
# Run as sudo on macOS to avoid restricted settings warnings and daemon disconnects
sudo -E nix run github:nix-community/nixos-anywhere -- \
  --debug -L --show-trace \
  --build-on remote \
  --option log-format bar-with-logs \
  --option max-substitution-jobs 32 \
  --option http-connections 50 \
  --option substituters "https://cache.nixos.org/ https://nix-community.cachix.org https://numtide.cachix.org https://hyprland.cachix.org https://cuda-maintainers.cachix.org" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" \
  --flake .#mercury \
  --generate-hardware-config nixos-facter hosts/mercury/facter.json \
  --extra-files "$HOME/mercury-extra" \
  root@mercury.lukashirsch.de
```

---

## 4. Post-Install Validation

### First Boot Checks (Console)

```bash
ssh root@mercury.lukashirsch.de
ip addr
ip route
systemctl status wg-quick-wg0.service
wg show
podman ps -a
systemctl status traefik.service blocky.service lldap.service authelia.service netbird-server.service netbird-dashboard.service vaultwarden.service
```

When `wg0` is healthy, switch to SSH over `10.10.1.1`.

### Validation Checklist

- [ ] `dig @10.10.1.1 mercury.lukashirsch.de` returns `10.10.1.1`
- [ ] [auth.lukashirsch.de](https://auth.lukashirsch.de) works
- [ ] [netbird.lukashirsch.de](https://netbird.lukashirsch.de) works
- [ ] NetBird login via Authelia OIDC works
- [ ] [vaultwarden.mars.lukashirsch.de](https://vaultwarden.mars.lukashirsch.de) is reachable from public internet
- [ ] [vaultwarden.mercury.lukashirsch.de](https://vaultwarden.mercury.lukashirsch.de) is reachable from public internet
- [ ] WireGuard peers reconnect

---

## 5. Service Configuration and Bootstrap

### Step-by-Step Bring-up

1. Verify Traefik health and TLS.
2. Verify Blocky DNS answers on `10.10.1.1`.
3. Bring up LLDAP and seed admin/groups.
4. Bring up Authelia and verify OIDC discovery.
5. Start NetBird server + dashboard.
6. Verify Vaultwarden cross-site (mars/mercury).

### LLDAP and Authelia Setup Guide

**LLDAP Bootstrap Intent:**

- Initial login using built-in admin.
- Create human admin: `admin-lkshrsch`.
- Create service bind user: `admin-authelia`.
- Recommended bind DN: `uid=admin-authelia,ou=people,dc=lukashirsch,dc=de`.

**Authelia OIDC Secret Management:**
The OIDC keys and hashes are managed via SOPS in [secrets/stacks-mercury.yaml](secrets/stacks-mercury.yaml).

*Optional generation with Authelia CLI:*

```bash
authelia crypto pair rsa generate --directory ./authelia-oidc
authelia crypto hash generate pbkdf2 --variant sha512 --iterations 310000 --password '<password>'
```

---

## 6. Migration Completion Checklist

- [ ] Add `authelia/oidc-private-key` to `secrets/stacks-mercury.yaml`
- [ ] Add `authelia/netbird-oidc-client-secret-hash` to `secrets/stacks-mercury.yaml`
- [ ] Set `authelia/ldap-user` to `uid=admin-authelia,ou=people,dc=lukashirsch,dc=de`
- [ ] Create LLDAP users `admin-lkshrsch` and `admin-authelia` after first initialization
- [ ] Verify no `CHANGE_ME` values remain in Podman/Sops configurations

---

## 7. Hardening and Maintenance

1. Move remaining WireGuard keys to SOPS.
2. Pin image versions (replace `latest` tags).
3. Optionally add Authelia forward-auth for Vaultwarden.
4. Restrict SSH to VPN paths only.
