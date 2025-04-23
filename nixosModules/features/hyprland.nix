{ lib, config, pkgs, inputs, ... }: {
  environment.systemPackages = with pkgs; [
    uwsm
    hyprpolkitagent
    hyprlock
    hypridle
    hyprpaper
    hyprsunset
    hyprpicker
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
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}
