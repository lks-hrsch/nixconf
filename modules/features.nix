{ ... }:
{
  flake = {
    nixosModules.features =
      { lib, ... }:
      {
        options.features = {
          desktop.enable = lib.mkEnableOption "desktop environment";
        };
      };

    darwinModules.features =
      { lib, ... }:
      {
        options.features = {
          desktop.enable = lib.mkEnableOption "desktop environment";
        };
      };
  };
}
