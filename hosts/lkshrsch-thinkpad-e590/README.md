# lkshrsch-thinkpad-e590

Lenovo ThinkPad E590 — the first NixOS **laptop** host in this repo, running
Hyprland + Noctalia with a hardened boot chain: UEFI Secure Boot (Lanzaboote),
LUKS2 full-disk encryption, TPM2 + YubiKey (FIDO2) unlock, and hibernation
support.

`/` is an ordinary persistent btrfs subvolume. An impermanent (wiped-every-boot)
root was built and then removed — see [Known issues](#known-issues).

## Hardware

| Component | Spec |
| :--- | :--- |
| CPU | Intel Core i7-8565U (Whiskey Lake) |
| GPU | Intel UHD Graphics 620 (iGPU) |
| RAM | 16 GB (planned upgrade to 32 GB) |
| Disk 1 | 512 GB NVMe (Toshiba KBG30ZMT512G) — OS, `$HOME`, swap |
| Disk 2 | 128 GB SATA SSD (SanDisk SDSSDP128G) — **currently unused** |

## Disk layout

Declared in [`disk-config.nix`](./disk-config.nix) via `disko`. The disk is
addressed by `/dev/disk/by-id/*` serial, not `/dev/nvme0n1` — on this machine
the installer's own USB boot stick also enumerates as `/dev/sd*`, so a bare
letter isn't safe to trust for a full-disk-format target.

| Partition | Content | Mountpoint |
| :--- | :--- | :--- |
| ESP (1G, vfat) | — | `/boot` |
| `cryptswap` (LUKS2, 48G) | swap partition, `resumeDevice` | — (hibernate target) |
| `cryptroot` (LUKS2) | btrfs `@root` (`compress=lzo`) | `/` |
| `cryptroot` (LUKS2) | btrfs `@nix` (`compress=lzo`) | `/nix` |
| `cryptroot` (LUKS2) | btrfs `@home` (`compress=lzo`) | `/home` |
| `cryptroot` (LUKS2) | btrfs `@snapshots` (`compress=lzo`) | `/.snapshots` |

`lzo` over `zstd`: faster (de)compression, less CPU per I/O — the priority on a
laptop. Note btrfs accepts only `zlib`/`lzo`/`zstd`; `lz4` is **not** a valid
`compress=` value and mounting with it fails at install time with a bare
`wrong fs type, bad option, bad superblock`.

`@snapshots` is a reserved mountpoint only — no `snapper`/`btrbk` is configured
in this repo yet, so nothing writes to it until one is added.

The ESP is 1G rather than the usual 512M because lanzaboote stores a signed
kernel + initrd per generation and fills a small ESP quickly.

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
```

`cryptswap` is LUKS-wrapped with a **persistent** key (TPM2/FIDO2/passphrase),
not `swapDevices.randomEncryption` — a fresh per-boot key (as used on
`workstation-nixos`) would make the hibernated image undecryptable on resume.

## Access model

Read this before installing — it is easy to end up with a machine you cannot
administer.

- greetd uses `initial_session` (`modules/desktop/hyprland/base.nix`), i.e.
  **autologin** as `lkshrsch`. Reaching the desktop needs no password.
- `sudo` **does** need one (`security.sudo.wheelNeedsPassword = true`).
- `root` has no `authorizedKeys` and sshd runs `PermitRootLogin
  prohibit-password`, so there is no key-based root login either.
- `mutableUsers` is the NixOS default `true` and nothing in this host sets a
  declarative hash, so a fresh install has **no password for any account**.

Therefore step 4 of the runbook — setting passwords inside `nixos-enter`
before the first reboot — is not optional. Skip it and the only route to root
is reinstalling. `/etc/shadow` lives on the persistent `@root`, so this is a
genuine one-time step.

## First-install runbook

Run from `workstation-nixos`. Steps 6–8 are interactive **on the laptop** — a
YubiKey touch and a BIOS visit cannot be scripted.

**Plug in ethernet before starting.** No wifi credentials exist on a fresh
install, so without a cable the installed system has no network at all and
cannot be reached over SSH.

### 1. Pre-flight (workstation)

```bash
nix flake check
nix eval .#nixosConfigurations.lkshrsch-thinkpad-e590.config.system.build.toplevel.drvPath
```

New `.nix` files must be `git add`-ed before they take effect: this flake is a
git tree, and `nix` does not see untracked files. A host file that is present
on disk but untracked is silently ignored — the build succeeds without it.

### 2. Boot the target

Boot the official NixOS minimal ISO on the E590. In BIOS: Secure Boot
**disabled** for now, TPM **enabled**, boot mode UEFI-only (no CSM). Set a
password for the `nixos` user on the ISO and note its IP.

### 3. Install

```bash
# Recovery passphrase — used for both LUKS containers at install time
(umask 077; printf '%s' 'YOUR-RECOVERY-PASSPHRASE' > /tmp/cryptroot.key)

mkdir -p ~/e590-extra/etc/sops/age
install -m 600 ~/.config/sops/age/keys.txt ~/e590-extra/etc/sops/age/keys.txt

nix run github:nix-community/nixos-anywhere -- \
  --flake .#lkshrsch-thinkpad-e590 \
  --phases disko,install \
  --disk-encryption-keys /tmp/cryptroot.key /tmp/cryptroot.key \
  --extra-files ~/e590-extra \
  nixos@<laptop-ip>
```

`--phases disko,install` deliberately omits `reboot`, leaving the new system
mounted at `/mnt` for step 4.

`facter.json` is already committed from the first hardware scan — no need to
regenerate it. 1Password's SSH agent refuses automated signing, so this
command has to be run by hand — not by Claude.

### 4. Set passwords (required — see [Access model](#access-model))

```bash
ssh nixos@<laptop-ip>
sudo nixos-enter --root /mnt
passwd lkshrsch
passwd root
exit
sudo reboot
```

### 5. First boot

Unlock with the recovery passphrase from step 3. greetd autologins into
Hyprland. Confirm the machine is on the network (`ip -br addr`) and reachable
over SSH before continuing.

### 6. Secure Boot keys (on the laptop)

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

Secure Boot must be **on and enrolled before step 7** — PCR 7 measures exactly
this state; enrolling the TPM first binds to the wrong value.

### 7. TPM2 enrollment

`cryptswap` is `/dev/nvme0n1p2`, `cryptroot` is `/dev/nvme0n1p3` (ESP is p1):

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

PCR 7 alone (Secure Boot policy) survives kernel/generation updates, unlike
PCR 4/8/9. Re-enroll both after a BIOS update or key rotation (see below).

### 8. YubiKey enrollment

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
| `sudo true` | accepts the password set in step 4 |
| `ip -br addr` | `enp4s0` has a DHCP lease |
| `ls /run/secrets/` | sops secrets decrypted with the age key from `/etc/sops/age/keys.txt` |
| `bootctl status` | `Secure Boot: enabled (user)`, stub = lanzaboote |
| `sbctl verify` | all files in `/boot` signed |
| `sudo cryptsetup luksDump /dev/nvme0n1p3` | keyslots: passphrase, tpm2, fido2 |
| reboot with YubiKey removed | unlocks silently via TPM |
| reboot after a test `--wipe-slot=tpm2` | prompts, YubiKey touch unlocks |
| `swapon --show` | `/dev/mapper/cryptswap`, ~48G |
| `systemctl hibernate` then power on | resumes back into the session |
| `hyprctl monitors` | one output, matches `desktop.monitors.primary` |
| `vainfo` | `iHD` driver, no NVIDIA references |
| `systemctl --failed` | empty |

## Day-2 operations

- **TPM re-enrollment** (after a BIOS/firmware update changes PCR 7): rerun
  step 7's commands with `--wipe-slot=tpm2` added, against both
  `/dev/nvme0n1p3` and `/dev/nvme0n1p2`.
- **Add another YubiKey**: repeat step 8 for both devices; each key gets its
  own FIDO2 slot.
- **Lost all YubiKeys / TPM won't unlock**: boot to the recovery passphrase
  prompt (it always remains a valid key slot on both containers).
- **`sbctl` after a BIOS reset clears Secure Boot keys**: redo step 6 from
  `sudo sbctl create-keys` — no reinstall needed, the enrolled LUKS slots are
  untouched.
- **RAM upgrade to 32 GB**: no config change needed — the 48G swap partition
  already covers hibernating at 32G RAM with headroom.

### Faster reinstalls

A full reinstall re-uploads the whole closure. To reuse what is already on
`@nix`, boot the ISO and run disko in `mount` mode instead of `disko` mode:

```bash
# disko's mount mode does NOT open cryptroot — do it by hand first
sudo cryptsetup open /dev/disk/by-partlabel/disk-nvme-cryptroot cryptroot \
  --allow-discards --key-file /tmp/cryptroot.key

nix run github:nix-community/nixos-anywhere -- \
  --flake .#lkshrsch-thinkpad-e590 \
  --disko-mode mount \
  --disk-encryption-keys /tmp/cryptroot.key /tmp/cryptroot.key \
  --extra-files ~/e590-extra \
  --option max-substitution-jobs 32 \
  --option http-connections 50 \
  nixos@<laptop-ip>
```

Without the manual `cryptsetup open`, disko fails with
`mount: /mnt: special device /dev/mapper/cryptroot does not exist` — it opens
`cryptswap` but never `cryptroot`.

## Known issues

### SATA SSD disabled

The 128 GB SATA SSD is not configured. Its disko block is parked in
[`_sata-disabled.nix`](./_sata-disabled.nix) — the leading `_` excludes the
file from `import-tree` auto-discovery, so nothing in it is evaluated.

It held one LUKS container (`cryptdata`) with btrfs subvolumes for
Obsidian/Documents/Downloads, unlocked in stage 2 by a keyfile rather than in
initrd. `/dev/mapper/cryptdata` never appeared at boot, and the dependent
mounts stalled the machine, so it was pulled out wholesale. Root cause is
still unknown; the keyfile was verifiably enrolled in LUKS keyslot 1. The
on-disk container is untouched, so re-enabling it loses no data.

Until then Documents/Downloads/Obsidian.nosync are ordinary directories under
`/home` on the NVMe.

### Impermanence removed

A wiped-every-boot root was implemented (`@root-blank` + an initrd
`rollback-root` unit + `environment.persistence."/persist"`) and then removed
while chasing a boot stall that also predated it. The design notes worth
keeping if it is ever revisited:

- systemd creates nested subvolumes under `/` (`var/tmp`, `srv`,
  `var/lib/machines`, `var/lib/portables`). btrfs refuses to delete a subvolume
  that still contains others, so the rollback unit must delete those first or
  the wipe silently stops working.
- With a wiped `/`, `passwd` is pointless — `/etc/shadow` is regenerated blank
  every boot. Passwords must be declarative (`hashedPasswordFile`) and sourced
  from a persisted path, and that path must be `neededForBoot` because the
  activation script reads it before systemd mounts ordinary filesystems.
- The sops age key must move to the persisted path too
  (`sops.age.keyFile`), or every secret fails to decrypt after the first wipe.
- Journald only writes to disk if `/var/log/journal` exists — persisting
  `/var/lib/systemd/journal` (a plausible-looking wrong path) silently
  discards every boot's log, which is exactly what you need when debugging.

### Boot stall after "Started D-Bus System Message Bus"

Unresolved. The console freezes at that line, the machine never reaches the
network, and Ctrl+Alt+Fn does not switch VTs. It survived both the removal of
the SATA disk and the removal of impermanence. A crashed compositor holding
the VT in `KD_GRAPHICS` mode produces exactly this signature, so greetd/Hyprland
on the Intel iGPU is the leading suspect over anything in stage 1.

Useful next probe: temporarily `services.greetd.enable = lib.mkForce false;`
to boot to a plain getty, which separates "the system does not boot" from
"the desktop does not start".

## Deliberately out of scope

ZFS, impermanence, remote initrd unlock over SSH, per-host sops secrets,
WireGuard/netbird enrollment, Alloy monitoring, and `pcrlock`-based multi-PCR
binding.
