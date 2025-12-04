{ pkgs, ... }:
{
  # Linux-specific home-manager modules
  imports = [
    ./features/hyprland
    ./features/xdg.nix
    ./files/uwsm-env.nix
    ./guiProgramms/obsstudio.nix
    ./guiProgramms/thunderbird.nix
  ];

  home.packages = with pkgs; [
    fio
  ];
}
