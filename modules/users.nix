{ config, ... }:
{
  flake = {
    modules.nixos.users =
      {
        pkgs,
        lib,
        ...
      }:
      {
        users.groups = {
          video = { };
          render = { };
          apps = {
            gid = 568;
          };
          games = { };
        };

        users.users = {
          apps = {
            uid = 568;
            description = "apps service account";
            isSystemUser = true; # since UID<1000
            group = "apps";
          };

          lkshrsch = {
            home = "/home/lkshrsch";
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ config.repo.constants.sshPublicKey ];
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "docker"
              "video"
              "games"
            ];
          };
        };
      };

    modules.darwin.users =
      {
        pkgs,
        lib,
        ...
      }:
      {
        users.users = {
          apps = {
            uid = 568;
            description = "apps service account";
          };

          lkshrsch = {
            home = "/Users/lkshrsch";
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ config.repo.constants.sshPublicKey ];
          };
        };
      };
  };
}
