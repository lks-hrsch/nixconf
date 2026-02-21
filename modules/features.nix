{ ... }:
{
  flake = {
    nixosModules.features =
      { lib, ... }:
      {
        options.features = {
          desktop.enable = lib.mkEnableOption "desktop environment";
          gaming.enable = lib.mkEnableOption "gaming features";

          virtualisation.podman.enable = lib.mkEnableOption "Podman support";

          zfs.enable = lib.mkEnableOption "ZFS support";
          nas.enable = lib.mkEnableOption "Network Attached Storage (NAS) support";
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
