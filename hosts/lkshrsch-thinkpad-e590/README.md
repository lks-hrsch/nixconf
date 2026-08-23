# lkshrsch-thinkpad-e590

Lenovo ThinkPad E590 — the first NixOS **laptop** host in this repo, running
Hyprland + Noctalia with a hardened boot chain: UEFI Secure Boot (Lanzaboote),
LUKS2 full-disk encryption, TPM2 + YubiKey (FIDO2) unlock, and hibernation
support.

`/` is an ordinary persistent btrfs subvolume. An impermanent (wiped-every-boot)
root was built and then removed — see [Known issues](#known-issues).

## Status

| Piece | State |
| :--- | :--- |
| Install, boot, network (wired + wifi) | done |
| Hyprland + Noctalia on the iGPU (`iHD`) | done |
| Lanzaboote, keys enrolled, Secure Boot `enabled (user)` | done |
| TPM2 unlock, PCR 7, both LUKS containers | done |
| YubiKey FIDO2 slots | **pending** — recovery passphrase is the only backup until then |
| Hibernate/resume | **untested** — swap partition and `resumeDevice` are wired |
| SATA SSD | plain ext4 scratchpad at `/mnt/scratchpad` — see [`sata-scratchpad.nix`](./sata-scratchpad.nix) |
| Home NAS (`mars`) CIFS mounts | done — 7 shares under `/mnt/mars/*`, see [`home-nas-mounts.nix`](./home-nas-mounts.nix) |

## Hardware

| Component | Spec |
| :--- | :--- |
| CPU | Intel Core i7-8565U (Whiskey Lake) |
| GPU | Intel UHD Graphics 620 (iGPU) |
| RAM | 16 GB (planned upgrade to 32 GB) |
| Disk 1 | 512 GB NVMe (Toshiba KBG30ZMT512G) — OS, `$HOME`, swap |
| Disk 2 | 128 GB SATA SSD (SanDisk SDSSDP128G) — plain ext4, mounted at `/mnt/scratchpad` |

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

The 128 GB SATA SSD (`sda`) is outside disko/LUKS entirely — plain ext4,
declared in [`sata-scratchpad.nix`](./sata-scratchpad.nix), mounted at
`/mnt/scratchpad` with `nofail` since it's data, not boot-critical.

Seven CIFS shares from the home NAS (`mars.lukashirsch.de`) are mounted at
`/mnt/mars/{backup,benchmark,datasets,home,media,photos,university}`, declared
in [`home-nas-mounts.nix`](./home-nas-mounts.nix). All are `x-systemd.automount`
with a 60s idle timeout, so they only connect on first access.

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

Then place the **user** copy of the age key. `modules/sops.nix` reads two
separate paths — `/etc/sops/age/keys.txt` for the system (line 16) and
`~/.config/sops/age/keys.txt` for home-manager (line 36). `--extra-files` can
only stage the first: it runs before `/home/lkshrsch` exists, so the user copy
has to be made after first boot, or `home-manager-lkshrsch.service` fails
activation with `sops-install-secrets: cannot read keyfile`.

```bash
install -d -m 700 ~/.config/sops/age
sudo install -m 600 -o "$USER" -g users /etc/sops/age/keys.txt ~/.config/sops/age/keys.txt
systemctl --user restart sops-nix.service
sudo systemctl restart home-manager-lkshrsch.service
```

It is the same key — `.sops.yaml` has a single recipient, and every host gets a
copy of it.

Two more per-machine bits that Nix does not declare, both inside the 1Password
desktop app on the laptop:

1. **Settings → Developer → Use the SSH agent.** Off on every fresh install
   regardless of `modules/onepassword.nix`; it is stored in
   `~/.config/1Password/settings/`. Until it is on, `~/.1password/agent.sock`
   does not exist and every outgoing SSH fails, because `modules/ssh.nix` points
   `IdentityAgent` at that socket.
2. **The agent's vault filter.** With no `agent.toml` the agent only offers keys
   from the `Private` vault, so `ssh-add -l` reports "The agent has no
   identities":

   ```bash
   mkdir -p ~/.config/1Password/ssh
   printf '[[ssh-keys]]\nvault = "Private - Infrastructure"\n' > ~/.config/1Password/ssh/agent.toml
   SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
   ```

   The agent only reads this at startup, so toggle it off/on after editing.
   Invalid TOML makes the agent refuse to start entirely — `ssh-add` then says
   `Connection refused` instead of "no identities", and the reason is only
   visible in `~/.config/1Password/logs/1Password_r*.log`:
   `Failed to deserialize SSH agent configuration`.

Note this is about SSH *out of* the laptop. Incoming sshd is
`services.openssh` from `modules/ssh.nix` and needs nothing manual.

### 6. Secure Boot keys (on the laptop)

`sbctl` is in `environment.systemPackages` (`hardware-configuration.nix`), but
on a fresh install that package is not on the machine yet — the deploy that
brings it is the same one that enables lanzaboote, and lanzaboote refuses to
build a signed generation without an existing key bundle. Break the cycle with
a throwaway shell:

```bash
sudo nix shell nixpkgs#sbctl -c sbctl create-keys   # creates /var/lib/sbctl
```

Then enable `inputs.lanzaboote.nixosModules.lanzaboote` in
`hardware-configuration.nix` — the import, `boot.loader.systemd-boot.enable =
false`, and the `boot.lanzaboote` block — and deploy. Verify before rebooting:

```bash
sudo sbctl verify          # ESP is umask=0077, so every check here needs sudo
sudo bootctl status
```

Expect every `/boot/EFI/Linux/nixos-generation-*.efi` signed, and
`/boot/EFI/nixos/kernel-*.efi` **not** signed — lanzaboote signs only the UKI
stub, which embeds the kernel/initrd hashes and refuses to boot on mismatch.
Upstream's getting-started guide shows the same `✗` line as expected output.
Don't delete `/boot/EFI/nixos`: those are lanzaboote's own content-addressed
kernel and initrd, not systemd-boot leftovers.

Stale Type #1 entries in `/boot/loader/entries/` *are* leftovers, though, and
point at kernel paths that no longer exist. Nothing regenerates them once
`systemd-boot.enable = false`, and under Secure Boot they'd be dud menu
entries. Delete them; the UKIs are Type #2 and auto-discovered from the
filesystem:

```bash
sudo rm -f /boot/loader/entries/nixos-generation-*.conf
```

Reboot into BIOS, **clear the Secure Boot keys / enter Setup Mode**, boot back
into the installed system:

```bash
sudo sbctl enroll-keys --microsoft   # keeps option-ROM/firmware modules happy
sudo sbctl status                    # expect: Setup Mode ✗ Disabled
```

If that fails with `File is immutable: /sys/firmware/efi/efivars/...`, clear
the efivarfs write-protection flag on each file it names and re-run — the
enrollment rewrites those variables anyway. `chattr` lives in `e2fsprogs`,
which this host doesn't install (btrfs only), so borrow it:

```bash
sudo nix shell nixpkgs#e2fsprogs -c chattr -i \
  /sys/firmware/efi/efivars/KEK-8be4df61-93ca-11d2-aa0d-00e098032b8c \
  /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f
sudo sbctl enroll-keys --microsoft
```

Reboot, enable Secure Boot in BIOS, confirm:

```bash
sudo bootctl status | grep -i 'secure boot'   # expect: enabled (user)
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
| `sudo ls /run/secrets/` | sops secrets decrypted with the age key from `/etc/sops/age/keys.txt` |
| `systemctl --failed` | empty — a failed `home-manager-lkshrsch.service` means the step-5 user age key is missing |
| `sudo bootctl status` | `Secure Boot: enabled (user)` |
| `sudo sbctl status` | `Setup Mode ✗ Disabled`, `Vendor Keys microsoft` |
| `sudo sbctl verify` | every `EFI/Linux/*.efi` signed; `EFI/nixos/kernel-*.efi` unsigned is expected |
| `sudo cryptsetup luksDump /dev/nvme0n1p3` | keyslots: passphrase, tpm2, fido2 |
| reboot with YubiKey removed | unlocks silently via TPM |
| reboot after a test `--wipe-slot=tpm2` | prompts, YubiKey touch unlocks |
| `swapon --show` | `/dev/mapper/cryptswap`, ~48G |
| `systemctl hibernate` then power on | resumes back into the session |
| `hyprctl monitors` | one output, matches `desktop.monitors.primary` — only answers from inside the Hyprland session, never over SSH or a TTY |
| `nix shell nixpkgs#libva-utils -c vainfo` | `iHD` driver, no NVIDIA references (`vainfo` is not installed by default; `nix run` fails here — it looks for a `libva-utils` binary that does not exist) |

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

### SATA SSD: LUKS+btrfs abandoned, now plain ext4 scratch (resolved)

The 128 GB SATA SSD originally held one LUKS container (`cryptdata`) with
btrfs subvolumes for Obsidian/Documents/Downloads, unlocked in stage 2 by a
keyfile rather than in initrd. `/dev/mapper/cryptdata` never appeared at
boot, and the dependent mounts stalled the machine, so that layout was pulled
out wholesale (root cause never isolated; the keyfile was verifiably
enrolled in LUKS keyslot 1).

It's since been reformatted plain ext4 and is mounted at `/mnt/scratchpad`
via [`sata-scratchpad.nix`](./sata-scratchpad.nix) — see that file's header
for the one-time `mkfs.ext4` step. Documents/Downloads/Obsidian.nosync stay
ordinary directories under `/home` on the NVMe; this disk is scratch space
only.

### USB-C / UCSI not implemented in firmware

`ucsi_acpi USBC000:00: error -ENODEV: PPM init failed` on every boot. The
E590's ACPI tables don't implement the UCSI interface Linux expects for
USB-C role/alt-mode negotiation. Cosmetic — DisplayPort alt-mode over the
USB-C port still works via the normal DP/USB muxing, it's just not visible to
`ucsi_acpi`. No kernel-side fix; this is a firmware gap on Lenovo's side.

### Intermittent USB enumeration failures on the front USB-A port (`usb1-port2`)

Occasional `usb 1-2: device descriptor read/64, error -71` /
`Device not responding to setup address` bursts, always for a **low-speed**
device (mouse/receiver class — see `new low-speed USB device` in the same
burst), never for a plugged-in monitor. Points to a flaky cable, connector,
or peripheral on that one port rather than a driver or config problem;
nothing here to fix in Nix.

### BIOS / ME firmware not updatable via fwupd

`fwupdmgr get-devices` shows BIOS 1.25 (`Internal SPI Controller (BIOS)`) and
ME 12.0.35.1427 as present but not `updatable` — the SPI region is locked and
Lenovo doesn't publish E590 UEFI/ME images to LVFS. `fwupdmgr security` marks
`csme11 v12.0.35.1427` invalid for this reason. A BIOS/ME update, if ever
needed, means a manual flash from Lenovo's own installer — out of scope for
this repo.

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

### Boot stall after "Started D-Bus System Message Bus" (resolved)

For several installs the console froze at that line, the machine never reached
the network, and Ctrl+Alt+Fn would not switch VTs. It went away with the
removal of impermanence and its workarounds, and has not recurred.

Which change was decisive was never isolated — several landed together
(impermanence removed, the SATA mounts pulled out, `dhcpcd` forced off so it
stopped fighting NetworkManager). Kept here because the *signature* is worth
recognising: a stall right after D-Bus with dead VT switching means userspace,
not stage 1. The probe that separates "the system does not boot" from "the
desktop does not start" is `services.greetd.enable = lib.mkForce false;` — boot
to a plain getty and look again.

Related trap: journald only writes to disk if `/var/log/journal` exists. While
impermanence was persisting `/var/lib/systemd/journal` instead, every boot's
evidence was discarded — which is why this took so long to pin down.

## Deliberately out of scope

ZFS, impermanence, remote initrd unlock over SSH, per-host sops secrets,
WireGuard/netbird enrollment, Alloy monitoring, and `pcrlock`-based multi-PCR
binding.
