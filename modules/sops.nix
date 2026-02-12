{ ... }:
{
  flake.homeManagerModules.sops =
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
}
