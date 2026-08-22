{ inputs, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { lib, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # /home, /nix, /.snapshots are separate subvolumes and stay untouched —
      # only @root gets wiped. /persist (own subvolume, see disk-config.nix)
      # holds everything under / that must survive that wipe.
      environment.persistence."/persist" = {
        hideMounts = true;
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/sops/age/keys.txt" # secrets stop decrypting without this
        ];
        directories = [
          "/etc/NetworkManager/system-connections" # wifi credentials
          "/var/lib/bluetooth"
          "/var/lib/systemd/journal"
          "/var/lib/netbird-wt0"
          "/var/lib/containers" # rootful podman storage
          "/var/lib/nixos" # dynamic uid/gid allocations
        ];
      };

      # Some early boot state needs /persist mounted before local-fs.target.
      fileSystems."/persist".neededForBoot = true;

      # Wipe @root back to its blank state on every boot. Ordered after LUKS
      # unlock (cryptroot is already open by then) and before the real root
      # is mounted.
      boot.initrd.systemd.services.rollback-root = {
        description = "Reset / to its blank snapshot";
        wantedBy = [ "initrd.target" ];
        after = [ "systemd-cryptsetup@cryptroot.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /mnt
          mount -o subvol=/ /dev/mapper/cryptroot /mnt
          btrfs subvolume delete /mnt/@root
          btrfs subvolume snapshot /mnt/@root-blank /mnt/@root
          umount /mnt
        '';
      };
    };
}
