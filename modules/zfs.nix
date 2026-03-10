_: {
  flake.modules.nixos.zfs =
    { ... }:
    {
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
}
