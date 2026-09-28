{ config, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    { pkgs, ... }:
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
        dhcpcd.enable = false;
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
      desktop.bar = {
        start = [
          "control-center"
          "workspaces"
          "tray"
        ];
        end = [
          "CPU"
          "ram"
          "gpu"
          "network"
          "caffeine"
          "battery"
          "power_profile"
          "date"
          "clock"
        ];
      };
      # 1920x1080 panel: keep the defaults' offsets from centre / bottom edge.
      desktop.lockscreen = {
        "lockscreen-login-box@eDP-1" = {
          cx = 960.0;
          cy = 957.0;
        };
        "lockscreen-widget-0000000000000001" = {
          cx = 960.0;
          cy = 808.0;
        }; # media
        "lockscreen-widget-0000000000000002" = {
          cx = 1520.0;
          cy = 192.0;
        }; # weather
        "lockscreen-widget-0000000000000003" = {
          cx = 976.0;
          cy = 192.0;
        }; # clock
      };

      services.fwupd.enable = true;

      boot.kernelParams = [ "intel_iommu=on" ];

      system.stateVersion = "26.05";
    };
}
