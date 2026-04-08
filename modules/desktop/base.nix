_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            fcitx5-mozc
            fcitx5-gtk
            qt6Packages.fcitx5-configtool
          ];
        };
      };
    };

  flake.modules.homeManager.desktop =
    { lib, osConfig, ... }:
    {
      xdg = {
        enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          extraConfig = {
            XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
          };
        };
      };
    };
}
