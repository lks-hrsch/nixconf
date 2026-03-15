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
      imports =
        with config.flake.modules.nixos;
        [
          base
          podman
          inputs.disko.nixosModules.default
          inputs.nixos-facter-modules.nixosModules.facter
          (modulesPath + "/installer/scan/not-detected.nix")
          (modulesPath + "/profiles/qemu-guest.nix")
        ]
        ++ lib.optional (builtins.pathExists ./facter.nix) ./facter.nix;

      networking.hostName = "mercury";

      system.stateVersion = "25.11";
    };
}
