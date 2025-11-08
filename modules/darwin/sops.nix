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
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      "ssh-public-key" = { };
    };
  };
}
