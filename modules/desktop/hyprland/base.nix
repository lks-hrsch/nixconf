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
      # ponytail: FetchContent fallback needs network mid-build if find_package
      # misses glaze <8 — see overlays/glaze7.nix. Drop once Hyprland's
      # CMakeLists accepts glaze 8.x upstream.
      hyprland = hyprlandPkg.hyprland.override { glaze-hyprland = pkgs.glaze7; };
    in
    {
      nixpkgs.overlays = [ config.repo.overlays.glaze7 ];

      environment.systemPackages = with pkgs; [
        uwsm
      ];

      security.pam.services.greetd.enableGnomeKeyring = true;

      services.greetd = {
        enable = true;
        settings = rec {
          initial_session = {
            command = "${lib.getExe pkgs.uwsm} start -eD Hyprland ${hyprland}/share/wayland-sessions/hyprland.desktop";
            user = config.flake.users.owner.username;
          };
          default_session = initial_session;
        };
      };

      programs = {
        hyprland = {
          enable = true;
          withUWSM = true;
          package = hyprland;
          portalPackage = hyprlandPkg.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        xwayland.enable = true;
      };

      home-manager.users.${config.flake.users.owner.username}.imports =
        with config.flake.modules.homeManager; [
          desktop-hyprland-cliphist
          desktop-hyprland-hyprland
          desktop-hyprland-noctalia
          desktop-hyprland-uwsm-env
        ];
    };

}
