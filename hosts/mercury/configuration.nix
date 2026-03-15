## Edit this configuration file to define what should be installed on
## your system. Help is available in the configuration.nix(5) man page
## and in the NixOS manual (accessible by running `nixos-help`).

{ config, ... }:
{
  configurations.nixos."mercury".module =
    {
      lib,
      pkgs,
      modulesPath,
      inputs,
      ...
    }:
    {
      imports = with config.flake.modules.nixos; [
        base
        podman
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      facter.reportPath =
        if builtins.pathExists ./facter.json then
          ./facter.json
        else
          throw "Missing hosts/mercury/facter.json. Run nixos-anywhere with --generate-hardware-config nixos-facter hosts/mercury/facter.json.";

      networking.hostName = "mercury";
      hardware.graphics.enable = false; # not needed on a headless VPS Servers

      boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      system.stateVersion = "25.11";
    };
}
