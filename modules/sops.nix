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
            }
            // lib.optionalAttrs (config.networking.hostName == "mercury") {
              "root-password-hash" = {
                sopsFile = ../secrets/secrets-mercury.yaml;
                neededForUsers = true;
                owner = "root";
                group = "root";
                mode = "0400";
              };

              "wg0/private-key" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/public-key" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                owner = "root";
                group = "root";
                mode = "0400";
              };
              "wg0/preshared-keys/earth" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/earth";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/phobos" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mars-phobos";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/deimos" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mars-deimos";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/homeassistant-freitelsdorf" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/homeassistant-freitelsdorf";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/homeassistant-dresden-florain" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/homeassistant-dresden";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/lkshrsch-workstation-nixos" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/lkshrsch-workstation-nixos";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/florian-mbp" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/florian-mbp";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/mberger-mbp" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mberger-mbp";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/mschuett-win" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mschuett-win";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/mberger-iphone" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mberger-iphone";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };
              "wg0/preshared-keys/mschuett-tablett" = {
                sopsFile = ../secrets/wireguard-mercury.yaml;
                key = "wg0/peer-preshared-keys/mschuett-tablett";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "wg-quick-wg0.service" ];
              };

              "mercury/traefik/cloudflare-dns-api-token" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "traefik/cloudflare-dns-api-token";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "traefik.service" ];
              };

              "mercury/lldap/jwt-secret" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "lldap/jwt-secret";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "lldap.service" ];
              };
              "mercury/lldap/ldap-user-pass" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "lldap/ldap-user-pass";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "lldap.service" ];
              };

              "mercury/authelia/jwt-secret" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/jwt-secret";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/ldap-user" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/ldap-user";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/ldap-password" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/ldap-password";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/session-secret" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/session-secret";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/oidc-hmac-secret" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/oidc-hmac-secret";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/oidc-private-key" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/oidc-private-key";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };
              "mercury/authelia/netbird-client-secret-hash" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "authelia/netbird-oidc-client-secret-hash";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "authelia.service" ];
              };

              "mercury/netbird/auth-secret" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "netbird/auth-secret";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "netbird-server.service" ];
              };
              "mercury/netbird/auth-secret-client" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "netbird/auth-secret-client";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "netbird-dashboard.service" ];
              };
              "mercury/netbird/encryption-key" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "netbird/encryption-key";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "netbird-server.service" ];
              };
              "mercury/netbird/proxy-token" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "netbird/proxy-token";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "netbird-proxy.service" ];
              };
              "mercury/netbird/proxy-token-id" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "netbird/proxy-token-id";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "netbird-proxy.service" ];
              };
              "mercury/vaultwarden/admin-token" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "vaultwarden/admin-token";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "vaultwarden.service" ];
              };
              "mercury/vaultwarden/smtp-username" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "vaultwarden/smtp-username";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "vaultwarden.service" ];
              };
              "mercury/vaultwarden/smtp-password" = {
                sopsFile = ../secrets/stacks-mercury.yaml;
                key = "vaultwarden/smtp-password";
                owner = "root";
                group = "root";
                mode = "0400";
                restartUnits = [ "vaultwarden.service" ];
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
