_: {
  flake = {
    # System-level SOPS configuration (NixOS and Darwin)
    modules =
      let
        commonSystemSops =
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
      in
      {
        nixos.sops = commonSystemSops;
        darwin.sops = commonSystemSops;

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

                # OpenCode provider credentials — decrypted at activation time.
                # Referenced at opencode runtime via `{file:...}` substitution so
                # no secret is ever baked into the Nix store.
                "opencode/provider/anthropic/base-url" = { };
                "opencode/provider/anthropic/api-key" = { };
                "opencode/provider/develappers/base-url" = { };
                "opencode/provider/develappers/api-key" = { };
                 "opencode/provider/workstation-nixos/base-url" = { };
                 "opencode/provider/workstation-nixos/api-key" = { };

                 "mcp/tavily/api-key" = { };
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
