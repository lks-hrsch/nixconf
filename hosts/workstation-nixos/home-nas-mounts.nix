outer: {
  configurations.nixos."workstation-nixos".module =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (outer.config.flake.users) owner;
      ip = "192.168.1.16";
      automount_opts = "x-systemd.automount,noauto,_netdev,x-systemd.idle-timeout=60,x-systemd.mount-timeout=5s,x-systemd.requires=network-online.target,x-systemd.after=network-online.target";
    in
    {
      sops.secrets."smb-credentials-mars" = {
        owner = owner.username;
      };

      services.gvfs.enable = true;
      environment.systemPackages = [
        pkgs.samba
        pkgs.cifs-utils
      ];

      fileSystems = {
        "/mnt/mars/backup" = {
          device = "//${ip}/backup";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/benchmark" = {
          device = "//${ip}/benchmark";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/home" = {
          device = "//${ip}/lkshrsch";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/media" = {
          device = "//${ip}/media";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/photos" = {
          device = "//${ip}/photos";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/university" = {
          device = "//${ip}/university";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/datasets" = {
          device = "//${ip}/datasets";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };
      };
    };
}
