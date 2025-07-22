{ lib, ... }:
{
  options.features = {
    desktop.enable = lib.mkEnableOption "desktop environment";
    gaming.enable = lib.mkEnableOption "gaming features";

    zfs.enable = lib.mkEnableOption "ZFS support";
    nas.enable = lib.mkEnableOption "Network Attached Storage (NAS) support";
  };

  imports = [
    ./features
    ./programs
    ./services

    ./home-nas-mounts.nix
    ./users.nix
  ];

}
