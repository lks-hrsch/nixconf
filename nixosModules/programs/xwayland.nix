{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    programs.xwayland.enable = true;
  };
}
