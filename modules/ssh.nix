{ inputs, ... }:
{
  flake = {
    nixosModules.ssh = { config, ... }: {
      services.openssh = {
        enable = true;
        authorizedKeysFiles = [ config.sops.secrets."ssh-public-key".path ];
      };
    };

    darwinModules.ssh = { config, ... }: {
      services.openssh = {
        enable = true;
        authorizedKeysFiles = [ config.sops.secrets."ssh-public-key".path ];
      };
    };

    homeManagerModules.ssh = { pkgs, config, ... }:
    let
      # Platform-specific 1Password agent socket path
      onePasswordAgent =
        if pkgs.stdenv.isLinux then
          "~/.1password/agent.sock"
        else
          ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [ "${config.sops.secrets."ssh-extra-config".path}" ];
        matchBlocks."*" = {
          identityAgent = onePasswordAgent;
        };
      };
    };
  };
}
