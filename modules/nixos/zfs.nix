_: {
  flake.modules.nixos.zfs = _: {
    boot = {
      initrd = {
        supportedFilesystems = [ "zfs" ];
      };
      supportedFilesystems = [ "zfs" ];
      zfs = {
        # TODO
        # Adopt the new safe default early. forceImportRoot=true risks importing
        # a pool that was previously exported on another system; false is the new
        # default from 26.11 on.
        forceImportRoot = false;
      };
    };

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
