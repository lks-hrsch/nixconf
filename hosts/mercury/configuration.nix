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
        alloy
        podman
        netbird
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      facter.reportPath =
        if builtins.pathExists ./facter.json then
          ./facter.json
        else
          throw "Missing hosts/mercury/facter.json. Run nixos-anywhere with --generate-hardware-config nixos-facter hosts/mercury/facter.json.";

      networking = {
        hostName = "mercury";
        hosts = {
          "127.0.0.1" = [
            "open-webui.deimos.mars.lukashirsch.de"
            "netbird.lukashirsch.de"
            "authelia.lukashirsch.de"
            "auth.lukashirsch.de"
          ];
        };
        # netcup nameservers
        nameservers = [
          "46.38.225.230"
          "46.38.252.230"
          "2a03:4000:0:1::e1e6"
        ];
      };
      hardware.graphics.enable = false; # not needed on a headless VPS Servers

      boot = {
        loader.grub = {
          efiSupport = true;
          efiInstallAsRemovable = true;
        };
        kernel.sysctl = {
          "net.core.rmem_max" = 7500000;
          "net.core.wmem_max" = 7500000;
        };
      };

      system.stateVersion = "25.11";
    };
}
