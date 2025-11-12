{ lib, pkgs, ... }:
{
  options.features = {
    desktop.enable = lib.mkEnableOption "desktop environment";
  };

  imports = [
    ./programs
    ./sops.nix
    ./time.nix
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
