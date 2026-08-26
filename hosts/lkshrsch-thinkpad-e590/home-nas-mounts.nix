outer: {
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (outer.config.flake.users) owner;
      host = "mars.lukashirsch.de";
      automount_opts = "x-systemd.automount,noauto,_netdev,x-systemd.idle-timeout=60,x-systemd.mount-timeout=60s,x-systemd.requires=network-online.target,x-systemd.after=network-online.target,vers=3.1.1";
    in
    {
      sops.secrets."smb-credentials-mars" = {
        owner = owner.username;
      };

      # gvfs already enabled by the desktop module (Nautilus mount browsing).
      environment.systemPackages = [
        pkgs.cifs-utils
      ];

      fileSystems = {
        "/mnt/mars/backup" = {
          device = "//${host}/backup";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/benchmark" = {
          device = "//${host}/benchmark";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/home" = {
          device = "//${host}/home";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/media" = {
          device = "//${host}/media";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/photos" = {
          device = "//${host}/photos";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/university" = {
          device = "//${host}/university";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };

        "/mnt/mars/datasets" = {
          device = "//${host}/datasets";
          fsType = "cifs";
          options = [
            "${automount_opts},credentials=${config.sops.secrets."smb-credentials-mars".path},uid=1000,gid=100"
          ];
        };
      };
    };
}
