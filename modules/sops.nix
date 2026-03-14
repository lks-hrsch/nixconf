{ ... }:
{
  flake = {
    # System-level SOPS configuration (NixOS and Darwin)
    modules = {
      nixos.sops =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          environment.systemPackages = with pkgs; [
            # for decryption and encryption of secrets
            sops
            age
          ];

          sops = {
            age.keyFile = "/etc/sops/age/keys.txt";
            age.sshKeyPaths = [ ]; # Don't look for SSH keys, only use age keys
            gnupg.sshKeyPaths = [ ]; # Also disable for gnupg
            defaultSopsFile = ../secrets/secrets.yaml;
            defaultSopsFormat = "yaml";

            secrets = {
              "ssh-public-key" = { };
            }
            // lib.optionalAttrs (config.networking.hostName == "workstation-nixos") {
              "smb-credentials-mars" = {
                owner = config.flake.users.owner.username;
              };
              "wg0/preshared-key" = {
                sopsFile = ../secrets/wireguard-workstation-nixos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/private-key" = {
                sopsFile = ../secrets/wireguard-workstation-nixos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/public-key" = {
                sopsFile = ../secrets/wireguard-workstation-nixos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
            }
            // lib.optionalAttrs (config.networking.hostName == "deimos") {
              "wg0/preshared-key" = {
                sopsFile = ../secrets/wireguard-deimos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/private-key" = {
                sopsFile = ../secrets/wireguard-deimos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/public-key" = {
                sopsFile = ../secrets/wireguard-deimos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
            }
            // lib.optionalAttrs (config.networking.hostName == "phobos") {
              "wg0/preshared-key" = {
                sopsFile = ../secrets/wireguard-phobos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/private-key" = {
                sopsFile = ../secrets/wireguard-phobos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
              "wg0/public-key" = {
                sopsFile = ../secrets/wireguard-phobos.yaml;
                owner = "systemd-network";
                group = "systemd-network";
                mode = "0400";
                restartUnits = [ "systemd-networkd.service" ];
              };
            };
          };
        };

      darwin.sops =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          environment.systemPackages = with pkgs; [
            # for decryption and encryption of secrets
            sops
            age
          ];

          sops = {
            age.keyFile = "/etc/sops/age/keys.txt";
            age.sshKeyPaths = [ ]; # Don't look for SSH keys, only use age keys
            gnupg.sshKeyPaths = [ ]; # Also disable for gnupg
            defaultSopsFile = ../secrets/secrets.yaml;
            defaultSopsFormat = "yaml";

            secrets = {
              "ssh-public-key" = { };
            }
            // lib.optionalAttrs (config.networking.hostName == "MacBook-000553") {
              "wg0/preshared-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg0/private-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg0/public-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-rustlers42/preshared-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-rustlers42/private-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-rustlers42/public-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-impact-labs/preshared-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-impact-labs/private-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-impact-labs/public-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
              };
              "wg-toronto/preshared-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
                key = "wg-privadovpn-toronto/preshared-key";
              };
              "wg-toronto/private-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
                key = "wg-privadovpn-toronto/private-key";
              };
              "wg-toronto/public-key" = {
                sopsFile = ../secrets/wireguard-macbook-000553.yaml;
                key = "wg-privadovpn-toronto/public-key";
              };
            };
          };
        };

      # Home-Manager level SOPS configuration
      homeManager.sops =
        { config, lib, ... }:
        {
          sops = {
            age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
            # Don't look for SSH keys, only use age keys
            age.sshKeyPaths = [ ];
            # Also disable for gnupg
            gnupg.sshKeyPaths = [ ];
            defaultSopsFile = ../secrets/secrets.yaml;
            defaultSopsFormat = "yaml";

            secrets = {
              "ssh-extra-config" = { };
              "git/user-lks-hrsch" = { };
            };
          };

          launchd.agents.sops-nix = {
            config = {
              EnvironmentVariables = {
                PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
              };
            };
          };
        };
    };
  };
}
