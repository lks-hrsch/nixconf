{ config, ... }:
{
  flake = {
    users.owner = {
      username = "lkshrsch";
      uid = 1000;
      home = {
        nixos = "/home/lkshrsch";
        darwin = "/Users/lkshrsch";
      };
      extraGroups = [
        "wheel"
        "video"
        "games"
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
            linger = true; # Keep the user manager (tmux, user units) alive with no session open.
            inherit (config.flake.users.owner) extraGroups uid;
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
