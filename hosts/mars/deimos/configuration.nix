# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    inputs.self.outputs.modules.nixos.default
    inputs.self.outputs.modules.shared.default

    # Include the default incus configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"

    # Include podman stacks
    ./stacks
  ];

  features = {
    virtualisation.podman.enable = true;
    wireguard = {
      enable = true;
      address = "10.10.1.18/24";
      dns = [
        "10.10.1.1"
        "10.10.1.3"
      ];
      peers = [
        {
          publicKey = "eTYFEILoUH8pbFVU9WJpzdNGTPm4eLiDAQXmyO1M7wE=";
          allowedIPs = [
            "10.10.1.1/32"
            "10.10.1.64/28"
          ];
          endpoint = "mercury.lukashirsch.de:51821";
          persistentKeepalive = 25;
        }
        {
          publicKey = "65mINKiTOCgTIiGCSk5YpbSFdryFEnTrr9vGcHEL5yI=";
          allowedIPs = [ "10.10.1.3/32" ];
          endpoint = "earth.staudenstuebler.de:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  networking = {
    hostName = "deimos";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
    firewall = {
      enable = true;
    };
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = "192.168.1.13/24";
        Gateway = "192.168.1.1";
        DNS = [
          "192.168.1.1"
          "5.45.99.133" # mercury.lukashirsch.de
          "85.209.49.247" # earth.lukashirsch.de
        ];
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
