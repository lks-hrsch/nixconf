{ config, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    age.sshKeyPaths = [ ]; # Don't look for SSH keys, only use age keys
    gnupg.sshKeyPaths = [ ]; # Also disable for gnupg
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      "ssh-extra-config" = { };
      "git/user-lks-hrsch" = { };
    };
  };
}
