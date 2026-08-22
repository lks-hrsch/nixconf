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
                      # lz4 over zstd: faster, less CPU per I/O.
                      subvolumes = {
                        "/@root" = {
                          mountpoint = "/";
                          mountOptions = [
                            "compress=lz4"
                            "noatime"
                          ];
                        };
                        "/@nix" = {
                          mountpoint = "/nix";
                          mountOptions = [
                            "compress=lz4"
                            "noatime"
                          ];
                        };
                        "/@home" = {
                          mountpoint = "/home";
                          mountOptions = [
                            "compress=lz4"
                            "noatime"
                          ];
                        };
                        "/@snapshots" = {
                          mountpoint = "/.snapshots";
                          mountOptions = [
                            "compress=lz4"
                            "noatime"
                          ];
                        };
                        # Impermanence (see impermanence.nix). @root-blank: never
                        # mounted, stays empty forever — the initrd wipe unit
                        # snapshots it over @root on every boot. @persist:
                        # survives the wipe, holds bind-mount sources.
                        "/@root-blank" = {
                          mountpoint = null;
                        };
                        "/@persist" = {
                          mountpoint = "/persist";
                          mountOptions = [
                            "compress=lz4"
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

          # One LUKS container, btrfs subvolumes for Obsidian/Documents/
          # Downloads — they share one free-space pool instead of fixed sizes
          # locked in until a reformat. Unlocked late (not in
          # boot.initrd.luks.devices) via a keyfile on the decrypted root
          # (README, install step 7).
          sata = {
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
                    settings.allowDiscards = true;
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        "/@obsidian" = {
                          mountpoint = "/home/lkshrsch/Obsidian.nosync";
                          mountOptions = [ "noatime" ];
                        };
                        "/@documents" = {
                          mountpoint = "/home/lkshrsch/Documents";
                          mountOptions = [ "noatime" ];
                        };
                        "/@downloads" = {
                          mountpoint = "/home/lkshrsch/Downloads";
                          mountOptions = [ "noatime" ];
                        };
                        "/@snapshots" = {
                          mountpoint = "/.snapshots-data";
                          mountOptions = [ "noatime" ];
                        };
                      };
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
