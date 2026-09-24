_: {
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { lib, ... }:
    {
      disko.devices = {
        disk = {
          nvme = {
            # Pinned by serial — a bare /dev/nvme0n1 isn't safe to point a
            # full-disk format at.
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
                # Partition (not swapfile) so hibernate can resume; 48G covers
                # the planned 32G RAM. Persistent LUKS key, not
                # randomEncryption — a per-boot key makes the image
                # undecryptable on resume.
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
                    # Recovery passphrase, keyslot 0. TPM2/FIDO2 slots are
                    # enrolled post-install (README steps 7-8);
                    # crypttabExtraOpts makes initrd try those first.
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

          # SATA SSD disabled — see _sata-disabled.nix. Until it is fixed,
          # Documents/Downloads/Obsidian.nosync are plain dirs under /home.
        };
      };
    };
}
