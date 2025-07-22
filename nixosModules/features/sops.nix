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
    age.keyFile = "/home/lkshrsch/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets =
      {
        "ssh-public-key" = { };
      }
      // lib.optionalAttrs (config.networking.hostName == "workstation-nixos") {
        "smb-credentials-mars" = {
          owner = "lkshrsch";
        };
        "wg0/preshared-key" = {
          sopsFile = ../../secrets/wireguard-workstation-nixos.yaml;
        };
        "wg0/private-key" = {
          sopsFile = ../../secrets/wireguard-workstation-nixos.yaml;
        };
        "wg0/public-key" = {
          sopsFile = ../../secrets/wireguard-workstation-nixos.yaml;
        };
      };
  };
}
