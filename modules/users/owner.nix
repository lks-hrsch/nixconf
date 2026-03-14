{ config, ... }:
{
  flake.users.owner = {
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
    ];
  };

  flake.modules.nixos.users =
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
        extraGroups = config.flake.users.owner.extraGroups;
      };
    };

  flake.modules.darwin.users =
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
}
