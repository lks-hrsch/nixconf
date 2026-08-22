{ config, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { lib, ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        homeManager
        desktop
        desktop-hyprland
        pipewire
        avahi
        onepassword
        syncthing
        netbird
        podman
      ];

      networking = {
        hostName = "lkshrsch-thinkpad-e590";
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          wifi.powersave = true;
        };
      };

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # Confirm with `hyprctl monitors` on first boot.
      desktop.monitors.primary = "eDP-1";

      # SSD subvolumes (disk-config.nix) mount straight at their final home
      # paths — no bind-mount or xdg.userDirs override needed.

      system.stateVersion = "26.05";
    };
}
