{ config, inputs, ... }:
{
  flake.modules.nixos.desktop-hyprland =
    {
      lib,
      pkgs,
      ...
    }:
    let
      hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      environment.systemPackages = with pkgs; [
        uwsm
      ];

      security.pam.services.greetd.enableGnomeKeyring = true;

      services.greetd = {
        enable = true;
        settings = rec {
          initial_session = {
            command = "${lib.getExe pkgs.uwsm} start -eD Hyprland ${
              inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
            }/share/wayland-sessions/hyprland.desktop";
            user = config.flake.users.owner.username;
          };
          default_session = initial_session;
        };
      };

      programs = {
        hyprland = {
          enable = true;
          withUWSM = true;
          package = hyprlandPkg.hyprland;
          portalPackage = hyprlandPkg.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        xwayland.enable = true;
      };

      home-manager.users.${config.flake.users.owner.username}.imports =
        with config.flake.modules.homeManager; [
          desktop-hyprland-cliphist
          desktop-hyprland-hyprland
          desktop-hyprland-noctalia-shell
          desktop-hyprland-uwsm-env
        ];
    };

}
