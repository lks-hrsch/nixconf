# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  modulesPath,
  inputs,
  config,
  ...
}:

{
  imports = [
    inputs.self.outputs.nixosModules.default

    # Include the default incus configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  features = {
    virtualisation.podman.enable = true;
  };

  networking = {
    hostName = "deimos";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        8384 # Syncthing GUI
        22000 # Syncthing TCP sync
      ];
      allowedUDPPorts = [
        22000 # Syncthing TCP sync
        21027 # Syncthing discovery
      ];
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

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.syncthing.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=syncthing" ];
      };

      containers = {
        syncthing = {
          containerConfig = {
            image = "syncthing/syncthing:1.30";
            user = "568";
            group = "568";
            environments = {
              PUID = "568";
              PGID = "568";
            };
            publishPorts = [
              "8384:8384/tcp" # GUI
              "22000:22000/tcp" # TCP sync
              "22000:22000/udp" # QUIC
              "21027:21027/udp" # discovery (if you want LAN discovery)
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/mnt/nvme-pool/apps/syncthing:/var/syncthing"
              "/mnt/pool/home:/mnt/pool/home"
            ];
            networks = [ networks.syncthing.ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };

  system.stateVersion = "25.05"; # Did you read the comment?
}
