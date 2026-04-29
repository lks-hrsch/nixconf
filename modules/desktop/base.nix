_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      i18n.inputMethod = {
        enable = true;
        type = "ibus";
        ibus.engines = [ pkgs.ibus-engines.mozc ];
      };

      services.gnome.gnome-keyring.enable = true;
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
