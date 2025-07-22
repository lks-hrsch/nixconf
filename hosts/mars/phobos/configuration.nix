# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ modulesPath, inputs, ... }:

{
  imports = [
    inputs.self.outputs.nixosModules.default

    # Include the default incus configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking = {
    hostName = "phobos";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = "192.168.1.12/24";
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
