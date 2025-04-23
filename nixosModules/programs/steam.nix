{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
  ];


  # STEAM
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true; # https://github.com/NixOS/nixpkgs/issues/238305
  };

  programs.gamemode = {
    enable = true;
  };
}
