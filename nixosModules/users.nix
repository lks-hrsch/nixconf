{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.games = { }; # Declare the "games" group.

  users.users.lkshrsch = {
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
}
