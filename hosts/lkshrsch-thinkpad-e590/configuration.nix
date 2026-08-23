{ config, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { pkgs, lib, ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        podman
        alloy
        netbird
        onepassword
        yubikey
        flatpak
        avahi
        pipewire
        librepods
        syncthing
        desktop
        desktop-hyprland
        homeManager
      ];

      networking = {
        hostName = "lkshrsch-thinkpad-e590";
        hostId = "89b448ab"; # head -c 8 /etc/machine-id
        useDHCP = false;
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          wifi.powersave = true;
          plugins = [ pkgs.networkmanager-openvpn ];
        };
      };

      # Load-bearing with `dns = "systemd-resolved"` above: NM stops writing
      # /etc/resolv.conf, so without resolved nothing answers lookups while
      # raw-IP routing keeps working — it reads as a DNS-only outage.
      services.resolved.enable = true;

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      desktop.monitors.primary = "eDP-1"; # confirmed via `hyprctl monitors`
      desktop.bar.gpuStats = false; # UHD 620: no VRAM, no GPU hwmon — see noctalia.log

      services.fwupd.enable = true;

      boot.kernelParams = [ "intel_iommu=on" ];

      system.stateVersion = "26.05";
    };
}
