{
  lib,
  config,
  pkgs,
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
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      "ssh-public-key" = { };
    }
    // lib.optionalAttrs (config.networking.hostName == "workstation-nixos") {
      "smb-credentials-mars" = {
        owner = "lkshrsch";
      };
      "wg0/preshared-key" = {
        sopsFile = ../../../secrets/wireguard-workstation-nixos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/private-key" = {
        sopsFile = ../../../secrets/wireguard-workstation-nixos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/public-key" = {
        sopsFile = ../../../secrets/wireguard-workstation-nixos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
    }
    // lib.optionalAttrs (config.networking.hostName == "deimos") {
      "wg0/preshared-key" = {
        sopsFile = ../../../secrets/wireguard-deimos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/private-key" = {
        sopsFile = ../../../secrets/wireguard-deimos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/public-key" = {
        sopsFile = ../../../secrets/wireguard-deimos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
    }
    // lib.optionalAttrs (config.networking.hostName == "phobos") {
      "wg0/preshared-key" = {
        sopsFile = ../../../secrets/wireguard-phobos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/private-key" = {
        sopsFile = ../../../secrets/wireguard-phobos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
      "wg0/public-key" = {
        sopsFile = ../../../secrets/wireguard-phobos.yaml;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "systemd-networkd.service" ];
      };
    };
  };
}
