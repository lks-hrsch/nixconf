{ config, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { pkgs, lib, ... }:
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
        hostId = "89b448ab"; # head -c 8 /etc/machine-id
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          wifi.powersave = true;
          plugins = [ pkgs.networkmanager-openvpn ];
        };
      };

      # systemd-resolved is load-bearing: NM uses `dns = "systemd-resolved"`,
      # and networkd hands the wired link's DNS + split-DNS domains to it.
      services.resolved.enable = true;

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      desktop.monitors.primary = "eDP-1"; # confirmed via `hyprctl monitors`

      system.stateVersion = "26.05";
    };
}
