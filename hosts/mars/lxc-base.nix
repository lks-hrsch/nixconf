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
              DNS = [ "192.168.1.1" ];
              IPv6AcceptRA = true;
            };
            linkConfig.RequiredForOnline = "routable";
          };
        };

        # Rootful Podman in these unprivileged LXCs keeps container network
        # namespaces under /run/user/0/netns. Without linger, every root SSH
        # login mounts a fresh tmpfs over /run/user/0 and hides them, so a
        # container stopped during a deploy can't tear down its network and
        # leaves stale netavark DNAT rules that shadow the new container's
        # ports. Linger keeps one /run/user/0 mounted from boot, and the
        # containers start after it. `wants`, not `requires`, so stopping the
        # runtime dir never stops the containers.
        users.users.root.linger = lib.mkIf config.virtualisation.podman.enable true;
        systemd.services = lib.mkIf config.virtualisation.podman.enable (
          lib.genAttrs (builtins.attrNames config.virtualisation.quadlet.containers) (_: {
            after = [ "user-runtime-dir@0.service" ];
            wants = [ "user-runtime-dir@0.service" ];
          })
        );

        system.stateVersion = "25.05";
      };
    };
}
