_: {
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { lib, ... }:
    {
      disko.devices = {
        disk = {
          nvme = {
            # Toshiba KBG30ZMT512G, pinned by serial — bare /dev/nvme0n1 isn't
            # safe for a full-disk-format target.
            device = lib.mkDefault "/dev/disk/by-id/nvme-KBG30ZMT512G_TOSHIBA_79BPA0KZPQMN";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                esp = {
                  name = "ESP";
                  # 1G: lanzaboote signs several generations, 512M fills up fast.
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                # Real partition (not swapfile) for hibernate resume; 48G covers
                # the planned 32G RAM upgrade. LUKS with a persistent key (not
                # swapDevices.randomEncryption) — a fresh per-boot key would make
                # the hibernated image undecryptable on resume.
                swap = {
                  name = "swap";
                  size = "48G";
                  content = {
                    type = "luks";
                    name = "cryptswap";
                    passwordFile = "/tmp/cryptroot.key";
                    settings = {
                      allowDiscards = true;
                      crypttabExtraOpts = [
                        "tpm2-device=auto"
                        "fido2-device=auto"
                      ];
                    };
                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  };
                };
                cryptroot = {
                  name = "cryptroot";
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "cryptroot";
                    # Recovery passphrase (README). TPM2/FIDO2 slots are
                    # enrolled post-install; crypttabExtraOpts tells initrd to
                    # try them first.
                    passwordFile = "/tmp/cryptroot.key";
                    settings = {
                      allowDiscards = true;
                      crypttabExtraOpts = [
                        "tpm2-device=auto"
                        "fido2-device=auto"
                      ];
                    };
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      # lzo over zstd: faster, less CPU per I/O.
                      subvolumes = {
                        "/@root" = {
                          mountpoint = "/";
                          mountOptions = [
                            "compress=lzo"
                            "noatime"
                          ];
                        };
                        "/@nix" = {
                          mountpoint = "/nix";
                          mountOptions = [
                            "compress=lzo"
                            "noatime"
                          ];
                        };
                        "/@home" = {
                          mountpoint = "/home";
                          mountOptions = [
                            "compress=lzo"
                            "noatime"
                          ];
                        };
                        "/@snapshots" = {
                          mountpoint = "/.snapshots";
                          mountOptions = [
                            "compress=lzo"
                            "noatime"
                          ];
                        };
                      };
                    };
                  };
                };
              };
            };
          };

          # The SATA SSD is currently disabled — see _sata-disabled.nix (the
          # leading `_` keeps it out of import-tree). Its cryptdata device
          # never appeared at boot and blocked the machine from starting.
          # Until that is fixed, Documents/Downloads/Obsidian.nosync live as
          # plain directories under /home on the NVMe.
        };
      };
    };
}
