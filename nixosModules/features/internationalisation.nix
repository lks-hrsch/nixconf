{ pkgs, ... }:
{
  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocales = [
      "en_GB.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
          fcitx5-configtool
        ];
      };
    };
  };
}
