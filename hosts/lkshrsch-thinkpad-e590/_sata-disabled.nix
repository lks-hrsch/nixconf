# DISABLED — the leading `_` excludes this file from import-tree
# auto-discovery (see .claude/CLAUDE.md), so nothing here is evaluated.
#
# Why: the SATA SSD's stage-2 unlock never produced /dev/mapper/cryptdata at
# boot, so every mount below timed out and blocked the machine from coming up.
# Pulled out wholesale to get a bootable system; the NVMe carries everything
# in the meantime (Documents/Downloads/Obsidian.nosync are just ordinary
# directories under /home on @home).
#
# Unresolved: the crypttab entry did not unlock the device, despite the
# keyfile being enrolled in LUKS keyslot 1 (verified with
# `cryptsetup open --test-passphrase`) and shipped by --extra-files. Prime
# suspect is ordering/availability of either /etc/crypttab or the keyfile at
# the moment systemd's crypttab generator runs. Debug from a booted system:
#   systemctl status systemd-cryptsetup@cryptdata.service
#   journalctl -b -u systemd-cryptsetup@cryptdata.service
#   ls -l /etc/crypttab /etc/cryptsetup-keys.d/data.key
#
# NOTE: this was written while the host used impermanence, so the keyfile
# lived at /persist/etc/cryptsetup-keys.d/data.key to survive the root wipe.
# Impermanence is gone and / persists, so on re-enable the keyfile belongs at
# the ordinary /etc/cryptsetup-keys.d/data.key and the --extra-files staging
# path changes to match.
#
# To re-enable: rename to sata.nix, restore the crypttab entry in
# hardware-configuration.nix, and redeploy. The on-disk LUKS container and
# its subvolumes are untouched by disabling this — no data is lost.
_: {
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { lib, ... }:
    {
      disko.devices.disk.sata = {
        # SanDisk SDSSDP128G, pinned by serial — the installer's own USB
        # stick also shows up as /dev/sd* on this machine.
        device = lib.mkDefault "/dev/disk/by-id/ata-SanDisk_SDSSDP128G_152141400006";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            cryptdata = {
              name = "cryptdata";
              size = "100%";
              content = {
                type = "luks";
                name = "cryptdata";
                initrdUnlock = false;
                passwordFile = "/tmp/cryptroot.key";
                additionalKeyFiles = [ "/tmp/data.key" ];
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/@obsidian" = {
                      mountpoint = "/home/lkshrsch/Obsidian.nosync";
                      mountOptions = [
                        "noatime"
                        "nofail"
                        "x-systemd.device-timeout=5s"
                      ];
                    };
                    "/@documents" = {
                      mountpoint = "/home/lkshrsch/Documents";
                      mountOptions = [
                        "noatime"
                        "nofail"
                        "x-systemd.device-timeout=5s"
                      ];
                    };
                    "/@downloads" = {
                      mountpoint = "/home/lkshrsch/Downloads";
                      mountOptions = [
                        "noatime"
                        "nofail"
                        "x-systemd.device-timeout=5s"
                      ];
                    };
                    "/@snapshots" = {
                      mountpoint = "/.snapshots-data";
                      mountOptions = [
                        "noatime"
                        "nofail"
                        "x-systemd.device-timeout=5s"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
}
