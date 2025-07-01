{ ... }:
{

  imports = [
    ./features/hyprland.nix
    ./features/internationalisation.nix

    ./programs/1password.nix
    ./programs/dconf.nix
    ./programs/steam.nix
    ./programs/tmux.nix
    ./programs/xwayland.nix
    ./programs/zsh.nix

    ./services/avahi.nix
    ./services/flatpak.nix
    ./services/openssh.nix
    ./services/pipewire.nix
    ./services/zfs.nix
    ./services/syncthing.nix
    ./services/xserver.nix

    ./home-nas-mounts.nix
  ];

}
