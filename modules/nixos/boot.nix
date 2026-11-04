# https://mynixos.com/nixpkgs/options/boot
_: {
  flake.modules.nixos.boot =
    { lib, pkgs, ... }:
    {

      boot = {
        # always the latest LTS kernel
        kernelPackages = lib.mkDefault pkgs.linuxPackages_6_18;

        # Ignored on hosts that don't use systemd-boot (grub, containers).
        loader.systemd-boot = {
          # Keep at most 10 generations in /boot to prevent the EFI partition filling up.
          configurationLimit = lib.mkDefault 10;
          # Boot menu entry for memtest86+.
          memtest86.enable = lib.mkDefault true;
        };

        tmp.cleanOnBoot = true;
      };
    };
}
