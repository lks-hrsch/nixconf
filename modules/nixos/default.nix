{ lib, pkgs, ... }:
{
  options.features = {
    desktop.enable = lib.mkEnableOption "desktop environment";
    gaming.enable = lib.mkEnableOption "gaming features";

    virtualisation.podman.enable = lib.mkEnableOption "Podman support";

    zfs.enable = lib.mkEnableOption "ZFS support";
    nas.enable = lib.mkEnableOption "Network Attached Storage (NAS) support";
  };

  imports = [
    ./features
    ./programs
    ./services
    ./virtualisation

    ./home-nas-mounts.nix
    ./users.nix
  ];

  config = {
    # global system packages
    environment.systemPackages = with pkgs; [
      btop
      pciutils
      usbutils
    ];
  };

}
