{ config, ... }:
let
  inherit (config.flake.users.owner) username;
  inherit (config.flake.modules) homeManager nixos;
in
{
  flake.modules.nixos.desktop-hyprland =
    {
      pkgs,
      ...
    }:
    {
      imports = [ nixos.desktop-hyprland-noctalia-greeter ];

      home-manager.users.${username}.imports = with homeManager; [
        desktop-hyprland-cliphist
        desktop-hyprland-hyprland
        desktop-hyprland-noctalia
        desktop-hyprland-uwsm-env
      ];

      environment.systemPackages = with pkgs.unstable; [
        uwsm
      ];

      security.pam.services.greetd.enableGnomeKeyring = true;

      programs = {
        hyprland = {
          enable = true;
          withUWSM = true;
          package = pkgs.unstable.hyprland;
          portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        xwayland.enable = true;
      };
    };
}
