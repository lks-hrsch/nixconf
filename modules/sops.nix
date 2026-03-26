_: {
  flake = {
    # System-level SOPS configuration (NixOS and Darwin)
    modules = {
      nixos.sops =
        { pkgs, ... }:
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

            secrets."ssh-public-key" = { };
          };
        };

      darwin.sops =
        { pkgs, ... }:
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

            secrets."ssh-public-key" = { };
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
