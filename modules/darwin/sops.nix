{
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
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      "ssh-public-key" = { };
    };
  };
}
