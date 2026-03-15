# mercury - Ubuntu to NixOS Migration

Concise operator runbook for migrating mercury to the NixOS host definition in this repo.

## Status

- [x] Step 1 backup completed (stacks, docker inventory, volume archives, wg0.conf)
- [ ] Migration install not yet completed

---

## 0) Preconditions (workstation)

- [ ] netcup console access is available
- [ ] nixos-anywhere is available
  - nix shell github:nix-community/nixos-anywhere
- [ ] flake evaluates
  - nix flake check path:$PWD
- [ ] one hardware source exists
  - hosts/mercury/_hardware-configuration.nix or hosts/mercury/facter.nix
- [ ] SOPS age key exists at ~/.config/sops/age/keys.txt

---

## 1) Back up the current Ubuntu host

Status: already completed once, keep this as the re-run procedure.

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

## 2) Stage secrets and runtime files

Now managed by SOPS files in repo:

- secrets/stacks-mercury.yaml
- secrets/wireguard-mercury.yaml

Runtime materialized paths (created by sops-nix):

- /run/secrets/wg0/private-key
- /run/secrets/wg0/preshared-keys/*
- /run/secrets/mercury/*
- /run/secrets-rendered/mercury/*.env
- /run/secrets-rendered/mercury/*.yaml

Still required before first successful service bootstrap:

- authelia OIDC private key PEM
- authelia OIDC client secret hash for netbird-dashboard

Important:

- `mercury/netbird/auth-secret-client` is the raw confidential OIDC client secret used by the NetBird dashboard.
- `CHANGE_ME_NETBIRD_OIDC_CLIENT_SECRET_HASH` in Authelia is the hash of that same raw secret, not a second secret.

---

## 3) Generate hardware module (if not already done)

Option A:

```bash
# run on installer
nixos-generate-config --no-filesystems --root /
scp root@<installer-ip>:/etc/nixos/hardware-configuration.nix hosts/mercury/_hardware-configuration.nix
```

Option B:

```bash
nix run github:nix-community/nixos-facter -- --host root@<installer-ip> --output hosts/mercury/facter.nix
```

---

## 4) Build extra-files overlay

```bash
mkdir -p ~/mercury-extra/var/lib/mercury/secrets/wg0/preshared-keys
mkdir -p ~/mercury-extra/var/lib/mercury/netbird
mkdir -p ~/mercury-extra/var/lib/mercury/authelia
mkdir -p ~/mercury-extra/var/lib/mercury/lldap
mkdir -p ~/mercury-extra/var/lib/mercury/vaultwarden/data
mkdir -p ~/mercury-extra/var/lib/mercury/traefik/letsencrypt
mkdir -p ~/mercury-extra/etc/sops/age

# copy age key from this workstation into nixos-anywhere overlay
install -m 600 ~/.config/sops/age/keys.txt ~/mercury-extra/etc/sops/age/keys.txt

chmod 700 ~/mercury-extra/var/lib/mercury/secrets
chmod 600 ~/mercury-extra/var/lib/mercury/secrets/wg0/private-key
chmod 600 ~/mercury-extra/var/lib/mercury/secrets/wg0/preshared-keys/*
chmod 600 ~/mercury-extra/etc/sops/age/keys.txt
```

Minimal overlay for sops key only (recommended when all service secrets are in repo SOPS files already):

```bash
rm -rf ~/mercury-extra
mkdir -p ~/mercury-extra/etc/sops/age
install -m 600 ~/.config/sops/age/keys.txt ~/mercury-extra/etc/sops/age/keys.txt
```

---

## 5) Install with nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#mercury \
  --extra-files ~/mercury-extra \
  root@<installer-ip>
```

With explicit local key path source (same result):

```bash
tmp_extra="$HOME/mercury-extra"
rm -rf "$tmp_extra"
mkdir -p "$tmp_extra/etc/sops/age"
install -m 600 "$HOME/.config/sops/age/keys.txt" "$tmp_extra/etc/sops/age/keys.txt"

nix run github:nix-community/nixos-anywhere -- \
  --flake .#mercury \
  --extra-files "$tmp_extra" \
  root@<installer-ip>
```

Optional inline facter generation:

```bash
--generate-hardware-config nixos-facter hosts/mercury/facter.nix
```

---

## 6) First boot checks (console first)

```bash
ip addr
ip route
systemctl status wg-quick-wg0.service
wg show
podman ps -a
systemctl status traefik.service blocky.service lldap.service authelia.service netbird-server.service netbird-dashboard.service vaultwarden.service
```

When wg0 is healthy, switch to SSH over 10.10.1.1.

---

## 7) Service bring-up sequence

1. Verify Traefik health and TLS
2. Verify Blocky DNS answers on 10.10.1.1
3. Bring up LLDAP and seed admin/groups
4. Bring up Authelia and verify OIDC discovery
5. Start NetBird server + dashboard
6. Verify Vaultwarden on both hosts (mars and mercury hostnames) from a public internet client (no VPN)

### LLDAP bootstrap intent

- The initial LLDAP admin login remains the built-in first admin account from LLDAP bootstrap.
- After first login, create a human admin user `admin-lkshrsch`.
- Also create a dedicated LDAP bind user `admin-authelia` for Authelia.
- Store the bind DN for `admin-authelia` in `authelia/ldap-user` and its password in `authelia/ldap-password`.
- Recommended bind DN value: `uid=admin-authelia,ou=people,dc=lukashirsch,dc=de`

This keeps the human admin account and the service bind account separate.

### Generate Authelia OIDC key material

Recommended with Authelia CLI:

```bash
authelia crypto pair rsa generate --directory ./authelia-oidc
```

Portable `openssl` alternative:

```bash
openssl genrsa -out authelia-oidc-private.pem 2048
openssl rsa -in authelia-oidc-private.pem -outform PEM -pubout -out authelia-oidc-public.pem
```

Use the private key PEM content for `CHANGE_ME_AUTHELIA_OIDC_PRIVATE_KEY`.

Recommended SOPS target to add:

```yaml
authelia:
  oidc-private-key: |
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
```

### Generate the Authelia hash for the NetBird client secret

Generate the hash from the same raw secret value stored in `netbird/auth-secret-client`:

```bash
authelia crypto hash generate pbkdf2 --variant sha512 --iterations 310000 --password '<raw-netbird-auth-secret-client>'
```

That output becomes the Authelia client entry value for `client_secret`.

Recommended SOPS target to add:

```yaml
authelia:
  netbird-oidc-client-secret-hash: "$pbkdf2-sha512$..."
```

---

## 8) Validation checklist

- [ ] dig @10.10.1.1 mercury.lukashirsch.de returns 10.10.1.1
- [ ] [auth.lukashirsch.de](https://auth.lukashirsch.de) works
- [ ] [netbird.lukashirsch.de](https://netbird.lukashirsch.de) works
- [ ] NetBird login via Authelia OIDC works
- [ ] [vaultwarden.mars.lukashirsch.de](https://vaultwarden.mars.lukashirsch.de) is reachable from public internet
- [ ] [vaultwarden.mercury.lukashirsch.de](https://vaultwarden.mercury.lukashirsch.de) is reachable from public internet
- [ ] WireGuard peers reconnect

---

## 10) Missing Inputs Checklist

- [ ] Add `authelia/oidc-private-key` to secrets/stacks-mercury.yaml
- [ ] Add `authelia/netbird-oidc-client-secret-hash` to secrets/stacks-mercury.yaml
- [ ] Set `authelia/ldap-user` to `uid=admin-authelia,ou=people,dc=lukashirsch,dc=de`
- [ ] Create LLDAP users `admin-lkshrsch` and `admin-authelia` after first initialization
- [ ] Replace temporary CHANGE_ME values in authelia template with those SOPS keys

---

## 9) Post-migration hardening

1. Move WireGuard keys to SOPS-managed secrets
2. Pin image versions (replace latest tags)
3. Optionally add Authelia forward-auth for Vaultwarden
4. Keep SSH limited to VPN/admin paths
