_: {
  flake = {
    modules.nixos.features =
      { lib, ... }:
      {
        options.features = {
          virtualisation.podman.enable = lib.mkEnableOption "Podman support";

          zfs.enable = lib.mkEnableOption "ZFS support";
          nas.enable = lib.mkEnableOption "Network Attached Storage (NAS) support";
        };
      };
  };
}
