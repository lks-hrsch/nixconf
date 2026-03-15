_: {
  flake.modules.nixos.internationalisation =
    { ... }:
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
      };
    };
}
