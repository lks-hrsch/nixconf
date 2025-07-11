{ ... }:
{
  sops = {
    age.keyFile = "/home/lkshrsch/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
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
