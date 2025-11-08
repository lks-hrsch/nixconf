{ ... }:
{
  # Linux-specific home-manager modules
  imports = [
    ./features/hyprland
    ./features/xdg.nix
    ./files/uwsm-env.nix
    ./guiPrograms/obsstudio.nix
    ./guiPrograms/thunderbird.nix
  ];
}
