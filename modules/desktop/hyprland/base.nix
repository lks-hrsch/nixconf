{ inputs, ... }:
{
  flake.modules.nixos.desktop-hyprland-base =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        uwsm
      ];

      services.greetd = {
        enable = true;
        settings = rec {
          initial_session = {
            command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
            user = "lkshrsch";
          };
          default_session = initial_session;
        };
      };

      programs = {
        hyprland = {
          enable = true;
          withUWSM = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage =
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        xwayland.enable = true;
      };
    };

}
