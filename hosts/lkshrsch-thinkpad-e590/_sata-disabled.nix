# DISABLED — the leading `_` keeps this out of import-tree auto-discovery
# (see .claude/CLAUDE.md), so nothing here is evaluated.
#
# The stage-2 unlock never produced /dev/mapper/cryptdata, so every mount
# below timed out and blocked boot. Still unexplained: the keyfile was
# verifiably enrolled in LUKS keyslot 1 and shipped by --extra-files. Prime
# suspect is whether /etc/crypttab or the keyfile is available when systemd's
# crypttab generator runs. Debug from a booted system:
#   systemctl status systemd-cryptsetup@cryptdata.service
#   journalctl -b -u systemd-cryptsetup@cryptdata.service
#   ls -l /etc/crypttab /etc/cryptsetup-keys.d/data.key
#
# Written when the host used impermanence, so the keyfile lived at
# /persist/etc/cryptsetup-keys.d/data.key. That is gone — on re-enable it
# belongs at /etc/cryptsetup-keys.d/data.key, and the --extra-files staging
# path moves with it.
#
# To re-enable: rename to sata.nix, restore the crypttab entry in
# hardware-configuration.nix, redeploy. The on-disk container is untouched;
# no data is lost by leaving this off.
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
