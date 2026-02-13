{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
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

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.override {
        wayland-protocols = pkgs.unstable.wayland-protocols; # >= 1.45
        libinput = pkgs.unstable.libinput; # >= 1.28
        libxkbcommon = pkgs.unstable.libxkbcommon; # for xkb_keymap_new_from_names2
      };
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}
