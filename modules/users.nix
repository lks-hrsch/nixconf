_: {
  flake = {
    nixosModules.users =
      {
        pkgs,
        lib,
        constants,
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
            openssh.authorizedKeys.keys = [ constants.sshPublicKey ];
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

    darwinModules.users =
      {
        pkgs,
        lib,
        constants,
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
            openssh.authorizedKeys.keys = [ constants.sshPublicKey ];
          };
        };
      };
  };
}
