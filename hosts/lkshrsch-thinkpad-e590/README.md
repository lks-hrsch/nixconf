# lkshrsch-thinkpad-e590

Lenovo ThinkPad E590 — the first NixOS **laptop** host in this repo, running
Hyprland + Noctalia with a hardened boot chain: UEFI Secure Boot (Lanzaboote),
LUKS2 full-disk encryption on both drives, TPM2 + YubiKey (FIDO2) unlock,
hibernation support, and an impermanent root (wiped every boot).

## Hardware

| Component | Spec |
| :--- | :--- |
| CPU | Intel Core i7-8565U (Whiskey Lake) |
| GPU | Intel UHD Graphics 620 (iGPU) |
| RAM | 16 GB (planned upgrade to 32 GB) |
| Disk 1 | 512 GB NVMe (Toshiba KBG30ZMT512G) — OS + `~/repos` + swap |
| Disk 2 | 128 GB SATA SSD (SanDisk SDSSDP128G) — Obsidian, Documents, Downloads |

## Disk layout

Declared in [`disk-config.nix`](./disk-config.nix) via `disko`. Both disks are
addressed by `/dev/disk/by-id/*` serial, not `/dev/sda`/`/dev/nvme0n1` — on
this machine the installer's own USB boot stick also enumerates as `/dev/sd*`,
so a bare letter isn't safe to trust for a full-disk-format target.

| Disk | Partition | Content | Mountpoint |
| :--- | :--- | :--- | :--- |
| NVMe | ESP (1G, vfat) | — | `/boot` |
| NVMe | `cryptswap` (LUKS2, 48G) | swap partition, `resumeDevice` | — (hibernate target) |
| NVMe | `cryptroot` (LUKS2) | btrfs `@root` (`compress=lz4`) | `/` |
| NVMe | `cryptroot` (LUKS2) | btrfs `@nix` (`compress=lz4`) | `/nix` |
| NVMe | `cryptroot` (LUKS2) | btrfs `@home` (`compress=lz4`) | `/home` |
| NVMe | `cryptroot` (LUKS2) | btrfs `@snapshots` (`compress=lz4`) | `/.snapshots` |
| NVMe | `cryptroot` (LUKS2) | btrfs `@root-blank` (`compress=lz4`) | — (never mounted, rollback source) |
| NVMe | `cryptroot` (LUKS2) | btrfs `@persist` (`compress=lz4`) | `/persist` |
| SATA SSD | `cryptdata` (LUKS2) | btrfs `@obsidian` | `/home/lkshrsch/Obsidian.nosync` |
| SATA SSD | `cryptdata` (LUKS2) | btrfs `@documents` | `/home/lkshrsch/Documents` |
| SATA SSD | `cryptdata` (LUKS2) | btrfs `@downloads` | `/home/lkshrsch/Downloads` |
| SATA SSD | `cryptdata` (LUKS2) | btrfs `@snapshots` | `/.snapshots-data` |

`lz4` over `zstd` on the NVMe: faster (de)compression, less CPU per I/O — the
priority on a laptop's iGPU-only path. The SATA disk is one LUKS container
with three btrfs subvolumes rather than three fixed-size partitions: they
share one free-space pool dynamically instead of a size picked upfront and
locked in until a reformat. Each mounts directly at its final path, so no
bind-mount or `xdg.userDirs` override is needed: Documents/Downloads are
already home-manager's default XDG locations, and Obsidian.nosync (the global
`obsidianBasePath` constant, read by every host's
`modules/home-manager/{obsidian,mcp}.nix`) lands exactly where every other
host expects it under `$HOME`. `~/repos` needs no override — it stays on the
NVMe.

Both `@snapshots` subvolumes are reserved mountpoints only — no `snapper`/
`btrbk` is configured in this repo yet, so nothing writes to them until one
is added.

## Boot chain

```
UEFI firmware (Secure Boot ON)
  → Lanzaboote stub (signed, verified by firmware)
    → signed kernel + initrd (systemd-initrd)
      → LUKS2 "cryptswap" unlock (same TPM2/FIDO2/passphrase as cryptroot)
        → resume from hibernate, if a hibernation image is present
      → LUKS2 "cryptroot" unlock: TPM2 (PCR 7) if boot chain unchanged,
        else YubiKey FIDO2 touch, else recovery passphrase
        → btrfs @root → /
          → LUKS2 "cryptdata" unlock via an on-disk keyfile
            → btrfs @obsidian/@documents/@downloads → their mountpoints under $HOME
```

`cryptswap` is LUKS-wrapped with a **persistent** key (TPM2/FIDO2/passphrase),
not `swapDevices.randomEncryption` — a fresh per-boot key (as used on
`workstation-nixos`) would make the hibernated image undecryptable on resume.

`cryptdata` (the SATA SSD) is **not** in `boot.initrd.luks.devices` — it is
unlocked late, at userspace boot, using a keyfile that itself lives on the
already-decrypted root. That costs nothing extra at the TPM/YubiKey prompt and
is no weaker than `/`.

## Impermanence

`/` is wiped back to empty on every boot — see [`impermanence.nix`](./impermanence.nix).
`@root-blank` is created once at install time and never mounted again;
`boot.initrd.systemd.services.rollback-root` deletes `@root` and re-snapshots
it from `@root-blank` after LUKS unlock but before the real root is mounted.
`/home`, `/nix`, and `/.snapshots` are separate subvolumes and are untouched.

Anything under `/` that must survive the wipe is bind-mounted from `@persist`
(mounted at `/persist`) via `environment.persistence."/persist"`
([nix-community/impermanence](https://github.com/nix-community/impermanence)):
the sops age key, SSH host keys, `/etc/machine-id`, NetworkManager wifi
credentials, Bluetooth pairings, the journal, and netbird/podman state. Adding
a new stateful path later means adding it to that list — nothing else needs
to change.

## First-install runbook

Run from `workstation-nixos`. Steps 4–7 are interactive **on the laptop** — a
YubiKey touch and a BIOS visit cannot be scripted.

### 1. Pre-flight (workstation)

```bash
nix flake check
nix eval .#nixosConfigurations.lkshrsch-thinkpad-e590.config.system.build.toplevel.drvPath
```

### 2. Boot the target

Boot the official NixOS minimal ISO on the E590. In BIOS: Secure Boot
**disabled** for now, TPM **enabled**, boot mode UEFI-only (no CSM). Set a
root password on the ISO and note its IP.

### 3. Install

```bash
# Recovery passphrase — used for all three LUKS containers at install time
(umask 077; printf '%s' 'YOUR-RECOVERY-PASSPHRASE' > /tmp/cryptroot.key)

mkdir -p ~/e590-extra/etc/sops/age
install -m 600 ~/.config/sops/age/keys.txt ~/e590-extra/etc/sops/age/keys.txt

nix run github:nix-community/nixos-anywhere -- \
  --flake .#lkshrsch-thinkpad-e590 \
  --generate-hardware-config nixos-facter hosts/lkshrsch-thinkpad-e590/facter.json \
  --disk-encryption-keys /tmp/cryptroot.key /tmp/cryptroot.key \
  --extra-files ~/e590-extra \
  root@<laptop-ip>
```

Commit the generated `facter.json` afterwards. 1Password's SSH agent refuses
automated signing, so this command has to be run by hand — not by Claude.

### 4. Secure Boot keys (on the laptop)

```bash
sudo sbctl create-keys
```

Edit `hardware-configuration.nix`: comment out `boot.loader.systemd-boot.enable`
and uncomment the `lib.mkForce false` + `boot.lanzaboote` block, then

```bash
sudo nixos-rebuild switch --flake .#lkshrsch-thinkpad-e590
```

Reboot into BIOS, **clear the Secure Boot keys / enter Setup Mode**, boot back
into the installed system:

```bash
sudo sbctl enroll-keys --microsoft   # keeps option-ROM/firmware modules happy
sudo sbctl verify
```

Reboot, enable Secure Boot in BIOS, confirm:

```bash
bootctl status | grep -i 'secure boot'   # expect: enabled (user)
```

Secure Boot must be **on and enrolled before step 5** — PCR 7 measures exactly
this state; enrolling the TPM first binds to the wrong value.

### 5. TPM2 enrollment

`cryptroot` is `/dev/nvme0n1p3`, `cryptswap` is `/dev/nvme0n1p2` (ESP is p1):

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

PCR 7 alone (Secure Boot policy) survives kernel/generation updates, unlike
PCR 4/8/9. Re-enroll both after a BIOS update or key rotation (see below).

### 6. YubiKey enrollment

```bash
sudo systemd-cryptenroll --fido2-device=auto \
  --fido2-with-client-pin=yes /dev/nvme0n1p3
sudo systemd-cryptenroll --fido2-device=auto \
  --fido2-with-client-pin=yes /dev/nvme0n1p2
```

Repeat both with a **second YubiKey** before trusting this as the only
physical key. `crypttabExtraOpts` in `disk-config.nix` already tells initrd to
try `tpm2-device=auto`, then `fido2-device=auto`, then fall back to the
recovery passphrase, for both devices.

### 7. Unlock `cryptdata` (the SATA SSD) without a prompt each boot

```bash
sudo install -d -m 700 /etc/cryptsetup-keys.d
sudo dd if=/dev/urandom of=/etc/cryptsetup-keys.d/data.key bs=512 count=1
sudo chmod 400 /etc/cryptsetup-keys.d/data.key
sudo cryptsetup luksAddKey /dev/sda1 /etc/cryptsetup-keys.d/data.key
```

### 8. Verify

```bash
sudo cryptsetup luksDump /dev/nvme0n1p3   # expect: passphrase + tpm2 + fido2
sudo cryptsetup luksDump /dev/nvme0n1p2   # same, for cryptswap
```

## Verification

Before touching the laptop, on `workstation-nixos`:

```bash
nix run nixpkgs#statix -- check .
nix flake check
nix eval .#nixosConfigurations.lkshrsch-thinkpad-e590.config.system.build.toplevel.drvPath
# regression guard for the shared desktop-module edits — must still evaluate:
nix eval .#nixosConfigurations.workstation-nixos.config.system.build.toplevel.drvPath
```

After install, on the laptop:

| Check | Expected |
| :--- | :--- |
| `bootctl status` | `Secure Boot: enabled (user)`, stub = lanzaboote |
| `sbctl verify` | all files in `/boot` signed |
| `sudo cryptsetup luksDump /dev/nvme0n1p3` | keyslots: passphrase, tpm2, fido2 |
| reboot with YubiKey removed | unlocks silently via TPM |
| reboot after a test `--wipe-slot=tpm2` | prompts, YubiKey touch unlocks |
| `swapon --show` | `/dev/mapper/cryptswap`, ~48G |
| `systemctl hibernate` then power on | resumes back into the session |
| `lsblk -f` / `findmnt /home/lkshrsch/Documents` | btrfs subvolumes mounted |
| `hyprctl monitors` | one output, matches `desktop.monitors.primary` |
| `vainfo` | `iHD` driver, no NVIDIA references |
| `systemctl --failed` | empty |
| `touch /root/should-vanish; reboot` | file gone after reboot |
| `findmnt /etc/machine-id /etc/ssh/ssh_host_ed25519_key` | both bind-mounted from `/persist` |
| `ls /run/secrets/` after reboot | secrets still present — sops still decrypted with the persisted age key |

## Day-2 operations

- **TPM re-enrollment** (after a BIOS/firmware update changes PCR 7): rerun
  step 5's two `--wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7` commands
  against both `/dev/nvme0n1p3` and `/dev/nvme0n1p2`.
- **Add another YubiKey**: repeat step 6 above for both devices; each key
  gets its own FIDO2 slot.
- **Lost all YubiKeys / TPM won't unlock**: boot to the recovery passphrase
  prompt (it always remains a valid key slot on all five containers).
- **`sbctl` after a BIOS reset clears Secure Boot keys**: redo step 4 from
  `sudo sbctl create-keys` — no reinstall needed, the enrolled LUKS slots are
  untouched.
- **RAM upgrade to 32 GB**: no config change needed — the 48G swap partition
  already covers hibernating at 32G RAM with headroom.

## Deliberately out of scope

ZFS, `/home` impermanence (only `/` is wiped), remote initrd unlock over SSH,
per-host sops secrets, WireGuard/netbird enrollment, Alloy monitoring, and
`pcrlock`-based multi-PCR binding.
