{
  pkgs,
  lib,
  constants,
  ...
}:
{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users = {
    groups = {
      video = { };
      render = { };
      apps = {
        gid = 568;
      };
      games = { };
    };

    users = {
      apps = {
        uid = 568;
        description = "apps service account";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        isSystemUser = true; # since UID<1000
        group = "apps";
      };

      lkshrsch = {

        home = if pkgs.stdenv.isDarwin then "/Users/lkshrsch" else "/home/lkshrsch";
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ constants.sshPublicKey ];
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
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
}
