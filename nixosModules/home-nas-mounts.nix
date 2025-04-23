{ pkgs, ... }:
let
  ip = "192.168.1.11";
  automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.requires=network-online.target,x-systemd.after=network-online.target";
in
{
  services.gvfs.enable = true;
  # For mount.cifs, required unless domain name resolution is not needed.
  environment.systemPackages = [ pkgs.samba pkgs.cifs-utils ];

  fileSystems."/mnt/mars/backup" = {
    device = "//${ip}/backup";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };

  fileSystems."/mnt/mars/benchmark" = {
    device = "//${ip}/benchmark";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };

  fileSystems."/mnt/mars/home" = {
    device = "//${ip}/lkshrsch";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };

  fileSystems."/mnt/mars/media" = {
    device = "//${ip}/media";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };

  fileSystems."/mnt/mars/photos" = {
    device = "//${ip}/photos";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };

  fileSystems."/mnt/mars/university" = {
    device = "//${ip}/university";
    fsType = "cifs";
    options = [ "${automount_opts},credentials=/etc/nixos/secrets/smb-credentials-mars,uid=1000,gid=100" ];
  };
}
