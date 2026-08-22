_: {
  flake.modules.nixos.marsLxcBase =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      options.marsLxc = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "Static IP address with CIDR prefix (e.g. \"192.168.1.12/24\").";
        };
      };

      imports = [
        "${modulesPath}/virtualisation/lxc-container.nix"
      ];

      config = {
        nix.settings.sandbox = false;

        networking = {
          dhcpcd.enable = false;
          useDHCP = false;
          useHostResolvConf = false;
          firewall.enable = true;
        };

        systemd.network = {
          enable = true;
          networks."50-eth0" = {
            matchConfig.Name = "eth0";
            networkConfig = {
              Address = config.marsLxc.ip;
              Gateway = "192.168.1.1";
              DNS = [
                "192.168.1.1"
                "5.45.99.133" # mercury.lukashirsch.de
                "85.209.49.247" # earth.staudenstuebler.de
              ];
              IPv6AcceptRA = true;
            };
            linkConfig.RequiredForOnline = "routable";
          };
        };

        system.stateVersion = "25.05";
      };
    };
}
