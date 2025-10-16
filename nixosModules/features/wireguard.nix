{ lib, config, ... }:
let
  cfg = config.features.wireguard;
  types = lib.types;
in
{
  options.features.wireguard = {
    enable = lib.mkEnableOption "Enable WireGuard (systemd-networkd)";

    interfaceName = lib.mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name";
    };

    address = lib.mkOption {
      type = types.str;
      example = "10.10.1.1/24";
      description = "Interface address with prefix length";
    };

    dns = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Optional DNS servers to set on the interface";
    };

    peers = lib.mkOption {
      type = types.listOf (
        types.submodule (
          { config, ... }:
          {
            options = {
              publicKey = lib.mkOption {
                type = types.str;
                description = "Peer public key";
              };
              allowedIPs = lib.mkOption {
                type = types.listOf types.str;
                description = "Allowed IPs for the peer";
              };
              endpoint = lib.mkOption {
                type = types.str;
                description = "endpoint host:port";
              };
              persistentKeepalive = lib.mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Optional keepalive in seconds";
              };
            };
          }
        )
      );
      default = [ ];
      description = "List of WireGuard peers";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network.enable = lib.mkDefault true;

    systemd.network.netdevs."30-${cfg.interfaceName}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = cfg.interfaceName;
        MTUBytes = "1420";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."${cfg.interfaceName}/private-key".path;
      };
      wireguardPeers = lib.forEach cfg.peers (
        peer:
        {
          PublicKey = peer.publicKey;
          AllowedIPs = peer.allowedIPs;
          Endpoint = peer.endpoint;
          PresharedKeyFile = config.sops.secrets."${cfg.interfaceName}/preshared-key".path;
        }
        // (lib.optionalAttrs (peer.persistentKeepalive != null) {
          PersistentKeepalive = peer.persistentKeepalive;
        })
      );
    };

    systemd.network.networks."30-${cfg.interfaceName}" = {
      matchConfig.Name = cfg.interfaceName;
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        DHCP = "no";
        Address = [ cfg.address ];
        DNS = cfg.dns;
      };
    };
  };
}
