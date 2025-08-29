{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
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
        isSystemUser = true; # since UID<1000
        uid = 568;
        description = "apps service account";
        group = "apps";
      };
      lkshrsch = {
        isNormalUser = true;
        home = "/home/lkshrsch";
        shell = pkgs.zsh;
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
