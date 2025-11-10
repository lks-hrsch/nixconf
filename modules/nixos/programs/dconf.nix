{ lib, config, ... }:
{
  config = lib.mkIf config.features.desktop.enable {
    programs.dconf.enable = true;
  };
}
