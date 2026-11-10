{ config, ... }:
let
  inherit (config.flake.users.owner) username uid;
in
{
  flake.modules.nixos.home-nas-mounts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      smb = config.homeNasMountsSMB;
      nfs = config.homeNasMountsNFS;
    in
    {
      options = {
        homeNasMountsSMB = {
          enable = lib.mkEnableOption "Mars home-NAS CIFS automounts under /mnt/mars";

          server = lib.mkOption {
            type = lib.types.str;
            description = "NAS address — hostname or IP.";
            example = "mars.lukashirsch.de";
          };

          shares = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "SMB share names; each mounts at /mnt/mars/<share>.";
            example = [
              "home"
              "datasets"
            ];
          };

          cifsVersion = lib.mkOption {
            type = lib.types.str;
            default = "default";
            description = "SMB protocol version (the `vers=` mount option).";
          };

          mountTimeoutSec = lib.mkOption {
            type = lib.types.ints.positive;
            default = 5;
            description = "x-systemd.mount-timeout, in seconds.";
          };

          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Extra packages needed alongside cifs-utils (e.g. samba for gvfs browsing).";
          };
        };

        homeNasMountsNFS = {
          enable = lib.mkEnableOption "Mars home-NAS NFS automounts under /mnt/mars-nfs";

          server = lib.mkOption {
            type = lib.types.str;
            description = "NAS address — hostname or IP.";
            example = "192.168.1.16";
          };

          shares = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Dataset names under `exportRoot`; each mounts at /mnt/mars-nfs/<share>.";
            example = [ "datasets" ];
          };

          exportRoot = lib.mkOption {
            type = lib.types.str;
            default = "/mnt/pool";
            description = "Server path the shares are exported under.";
          };

          options = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "nfsvers=4.2"
              "hard"
              "noatime"
              "nconnect=8"
              "rsize=1048576"
              "wsize=1048576"
              "x-systemd.automount"
              "noauto"
              "x-systemd.idle-timeout=600"
            ];
            description = "Mount options for every NFS share.";
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf smb.enable {
          sops.secrets."smb-credentials-mars".owner = username;

          environment.systemPackages = [ pkgs.cifs-utils ] ++ smb.extraPackages;

          fileSystems = lib.genAttrs' smb.shares (
            share:
            lib.nameValuePair "/mnt/mars/${share}" {
              device = "//${smb.server}/${share}";
              fsType = "cifs";
              options = [
                (lib.concatStringsSep "," [
                  "x-systemd.automount"
                  "noauto"
                  "_netdev"
                  "x-systemd.idle-timeout=60"
                  "x-systemd.mount-timeout=${toString smb.mountTimeoutSec}s"
                  "x-systemd.requires=network-online.target"
                  "x-systemd.after=network-online.target"
                  "vers=${smb.cifsVersion}"
                  "credentials=${config.sops.secrets."smb-credentials-mars".path}"
                  "uid=${toString uid}"
                  "gid=100"
                ])
              ];
            }
          );
        })

        (lib.mkIf nfs.enable {
          boot.supportedFilesystems = [ "nfs" ];

          fileSystems = lib.genAttrs' nfs.shares (
            share:
            lib.nameValuePair "/mnt/mars-nfs/${share}" {
              device = "${nfs.server}:${nfs.exportRoot}/${share}";
              fsType = "nfs";
              inherit (nfs) options;
            }
          );
        })
      ];
    };
}
