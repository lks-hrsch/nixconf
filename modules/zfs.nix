_: {
  flake.nixosModules.zfs =
    { lib, config, ... }:
    {
      config = lib.mkIf config.features.zfs.enable {
        # ZFS services
        services.zfs = {
          autoScrub.enable = true;
          autoSnapshot = {
            enable = true;
            flags = "-k -p --utc";
          };
          trim.enable = true;
        };
      };
    };
}
