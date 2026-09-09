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
      cfg = config.homeNasMounts;
      shares = [
        "backup"
        "benchmark"
        "home"
        "media"
        "photos"
        "university"
        "datasets"
      ];
    in
    {
      options.homeNasMounts = {
        enable = lib.mkEnableOption "Mars home-NAS CIFS automounts";

        server = lib.mkOption {
          type = lib.types.str;
          description = "NAS address — hostname or IP.";
          example = "mars.lukashirsch.de";
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

      config = lib.mkIf cfg.enable {
        sops.secrets."smb-credentials-mars".owner = username;

        environment.systemPackages = [ pkgs.cifs-utils ] ++ cfg.extraPackages;

        fileSystems = lib.listToAttrs (
          map (share: {
            name = "/mnt/mars/${share}";
            value = {
              device = "//${cfg.server}/${share}";
              fsType = "cifs";
              options = [
                (lib.concatStringsSep "," [
                  "x-systemd.automount"
                  "noauto"
                  "_netdev"
                  "x-systemd.idle-timeout=60"
                  "x-systemd.mount-timeout=${toString cfg.mountTimeoutSec}s"
                  "x-systemd.requires=network-online.target"
                  "x-systemd.after=network-online.target"
                  "vers=${cfg.cifsVersion}"
                  "credentials=${config.sops.secrets."smb-credentials-mars".path}"
                  "uid=${toString uid}"
                  "gid=100"
                ])
              ];
            };
          }) shares
        );
      };
    };
}
