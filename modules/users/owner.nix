{ config, ... }:
{
  flake = {
    users.owner = {
      username = "lkshrsch";
      home = {
        nixos = "/home/lkshrsch";
        darwin = "/Users/lkshrsch";
      };
      extraGroups = [
        "wheel"
        "docker"
        "video"
        "games"
        "netbird-wt0"
      ];
    };

    modules = {
      nixos."users-owner" =
        {
          pkgs,
          ...
        }:
        {
          nix.settings.trusted-users = [ config.flake.users.owner.username ];

          users.users.${config.flake.users.owner.username} = {
            home = config.flake.users.owner.home.nixos;
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ config.repo.constants.sshPublicKey ];
            isNormalUser = true;
            inherit (config.flake.users.owner) extraGroups;
          };
        };

      darwin."users-owner" =
        {
          pkgs,
          ...
        }:
        {
          system.primaryUser = config.flake.users.owner.username;

          users.users.${config.flake.users.owner.username} = {
            home = config.flake.users.owner.home.darwin;
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ config.repo.constants.sshPublicKey ];
          };
        };
    };
  };
}
