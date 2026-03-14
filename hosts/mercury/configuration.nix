## Edit this configuration file to define what should be installed on
## your system. Help is available in the configuration.nix(5) man page
## and in the NixOS manual (accessible by running `nixos-help`).

{ config, ... }:
{
  configurations.nixos."mercury".module =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports =
        with config.flake.modules.nixos;
        [
          base
          podman
        ]
        ++ lib.optional (builtins.pathExists ./_hardware-configuration.nix) ./_hardware-configuration.nix
        ++ lib.optional (builtins.pathExists ./facter.nix) ./facter.nix;

      nix.settings.sandbox = false;

      environment.systemPackages = with pkgs; [
        curl
        jq
        wireguard-tools
      ];

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      networking = {
        hostName = "mercury";
        dhcpcd.enable = false;
        useDHCP = false;
        useHostResolvConf = false;
        firewall = {
          enable = true;
          checkReversePath = "loose";
        };
        nameservers = [
          "1.1.1.1"
          "1.0.0.1"
          "9.9.9.9"
        ];
      };

      services = {
        qemuGuest.enable = true;
        openssh.listenAddresses = [
          {
            addr = "10.10.1.1";
            port = 22;
          }
        ];
      };

      systemd.network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };

      system.stateVersion = "25.11"; # Did you read the comment?
    };
}
