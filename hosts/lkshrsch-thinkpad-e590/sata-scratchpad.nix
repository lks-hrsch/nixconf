# Internal 128GB SATA SSD (SanDisk SDSSDP128G), plain ext4 scratch space —
# replaces the never-working LUKS+btrfs layout that used to live here (was
# _sata-disabled.nix; deleted, disk was reformatted).
#
# One-time, destructive setup — run before the first rebuild that mounts this:
#   sudo mkfs.ext4 -L scratchpad /dev/disk/by-id/ata-SanDisk_SDSSDP128G_152141400006
outer: {
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    _:
    let
      inherit (outer.config.flake.users) owner;
    in
    {
      fileSystems."/mnt/scratchpad" = {
        device = "/dev/disk/by-id/ata-SanDisk_SDSSDP128G_152141400006";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail" # data disk, not boot-critical — don't block boot if it's missing
        ];
      };

      systemd.tmpfiles.rules = [
        "d /mnt/scratchpad 0755 ${owner.username} users -"
      ];
    };
}
