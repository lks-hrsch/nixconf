{ config, ... }:
{
  configurations.nixos."workstation-nixos".module =
    { pkgs, lib, ... }:
    let
      nv-fan-control = import ./_nv-fan-control.nix { inherit pkgs; };
      nv-oc = import ./_nv-oc.nix { inherit pkgs; };
      # RTX 4090 NVML limits (queried live): mem offset -2000..+6000 MHz,
      # power limit 10..600 W. 600 is the hardware ceiling, no headroom above it.
      nvMemOffset = 1000;
      nvPowerLimitWatts = 600;
    in
    {
      imports = with config.flake.modules.nixos; [
        base
        podman
        alloy
        netbird
        onepassword
        flatpak
        avahi
        pipewire
        librepods
        xserver
        zfs
        syncthing
        desktop
        desktop-hyprland
        gaming
        homeManager
      ];

      nixpkgs.config.cudaSupport = true;

      desktop.monitors = {
        primary = "DP-3";
        secondary = "DP-2";
      };

      networking = {
        hostName = "workstation-nixos";
        hostId = "99c58a86"; # head -c 8 /etc/machine-id
        # Split network stack: systemd-networkd owns the wired LAN (enp10s0,); NetworkManager owns WiFi + VPNs (openvpn / netbird / wireguard).
        useNetworkd = true;
        # Suppress the global `99-*` DHCP catch-all .networks.
        useDHCP = false;
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          wifi.powersave = true;
          plugins = [ pkgs.networkmanager-openvpn ];
          # Keep NM's hands off the wired NIC — networkd owns it.
          unmanaged = [ "interface-name:enp10s0" ];
        };
        firewall.allowedTCPPorts = [ 27040 ];
      };

      # systemd-resolved is load-bearing: NM uses `dns = "systemd-resolved"`,
      # and networkd hands the wired link's DNS + split-DNS domains to it.
      services.resolved.enable = true;
      systemd = {
        network = {
          enable = true;
          wait-online.extraArgs = [ "--interface=enp10s0" ];
          networks = {
            # Hand WiFi entirely to NetworkManager. nixos-facter emits a
            # `40-wlp11s0.network` (DHCP=yes); without this, networkd would run a
            # second DHCP client on the WiFi link NM owns.
            "05-wlp11s0-unmanaged" = {
              matchConfig.Name = "wlp11s0";
              linkConfig.Unmanaged = true;
            };
            "10-enp10s0-lan" = {
              matchConfig.Name = "enp10s0";
              networkConfig = {
                DHCP = "no";
                Address = "192.168.1.40/24";
                Gateway = "192.168.1.1";
                DNS = [ "192.168.1.1" ];
                # `~` prefix = routing-only split-DNS domains forwarded to resolved.
                Domains = "~mars.lukashirsch.de ~deimos.mars.lukashirsch.de";
                IPv6AcceptRA = true;
              };
            };
          };
        };
      };

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };

        nvidia-container-toolkit.enable = true;

        # Enable OpenGL
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
            libva
            vulkan-loader
          ];
        };

        nvidia = {
          # Modesetting is required.
          modesetting.enable = true;

          # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
          # Enable this if you have graphical corruption issues or application crashes after waking
          # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
          # of just the bare essentials.
          powerManagement.enable = true;

          # nixpkgs 26.05 defaults this to true for the open driver >= 595, which
          # drops the nvidia-suspend/resume/hibernate systemd units in favor of the
          # new kernel suspend-notifier path - that path hung S3 suspend on first
          # use (2026-06-10, journal ends at "PM: suspend entry (deep)").
          # NOTE: not proven that the notifier path alone caused the hang - the GPU
          # was already wedged by the Hyprland v0.55.3 monitor-disconnect SEGV 30s
          # earlier. External reports of standalone notifier hangs on 595 exist
          # though (open-gpu-kernel-modules#1157), so we keep the proven path.
          # Re-checked 2026-08-16 (Hyprland now 0.56.2, noctalia v5): driver is
          # still 595.71.05, same as the hang - no bump happened, so the SEGV
          # confounder being gone proves nothing about the notifier path itself.
          # Upstream #1157 is still open with no fix version. Units-based path
          # confirmed working since (clean suspend/resume 2026-07-12, journal).
          # Retry condition, not a date: drop this line once
          # `hardware.nvidia.package.version` moves past 595.71.05, then verify
          # via /proc/driver/nvidia/params and a real `systemctl suspend` test
          # before trusting it unattended.
          powerManagement.kernelSuspendNotifier = false;

          # Use the NVidia open source kernel module (not to be confused with the
          # independent third-party "nouveau" open source driver).
          # Support is limited to the Turing and later architectures. Full list of
          # supported GPUs is at:
          # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
          open = true;
        };

        opentabletdriver = {
          enable = true;
          daemon.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        nixos-icons
        libva-utils # vainfo
        vulkan-tools # vulkaninfo, vkcube
        lm_sensors
        ffmpeg_6-full
        gnugrep
        dig
        nv-fan-control
        nv-oc
        unstable.eduvpn-client
      ];

      # systemd >= 256 freezes user sessions before sleep, which can deadlock
      # against nvidia-suspend saving VRAM (see nixpkgs#371058); boot -1 on
      # 2026-06-10 froze user.slice right before the suspend hang.
      # NOTE: belt-and-braces, added together with kernelSuspendNotifier=false -
      # the two were not tested independently.
      # TODO(2026-Q3): once suspend has been stable for a while, try removing
      # this and verify suspend still works (isolates which fix was load-bearing);
      # drop entirely when nixpkgs#371058 is resolved.
      systemd.services."systemd-suspend".environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      systemd.services.nvidia-fan-startup = {
        description = "Set NVIDIA Fan Speed at Startup";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${nv-fan-control}/bin/nv-fan-control 55";
        };
      };

      # ponytail: boot-only, like nvidia-fan-startup - offsets revert after
      # suspend/resume. If that bites, add suspend.target/hibernate.target to
      # after+wantedBy (the systemd inversion idiom re-runs the unit on wake);
      # same fix applies to nvidia-fan-startup.
      systemd.services.nvidia-oc-startup = {
        description = "Set NVIDIA Memory Overclock and Power Limit at Startup";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${nv-oc}/bin/nv-oc ${toString nvMemOffset} ${toString nvPowerLimitWatts}";
        };
      };

      # This option defines the first version of NixOS you have installed on this particular machine,
      # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
      #
      # Most users should NEVER change this value after the initial install, for any reason,
      # even if you've upgraded your system to a new NixOS release.
      #
      # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
      # so changing it will NOT upgrade your system. See:
      # https://nixos.org/manual/nixos/stable/#sec-upgrading
      #
      # This value being lower than the current NixOS release does NOT mean your system is
      # out of date, out of support, or vulnerable.
      #
      # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
      # and migrated your data accordingly.
      #
      # For more information, see `man configuration.nix` or:
      # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
      system.stateVersion = "24.11";

      home-manager.users.${config.flake.users.owner.username}.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              pkg-config
              rustdesk
              osu-lazer
              gimp3

              # dev tools
              # nasm # nasm compiler
              # gnumake # GNU make
              # cmake
              # ninja
              # clang
              # clang-tools

              # cudatoolkit
              linuxPackages.nvidia_x11

              # dev virtualization
              # grub2
              # libisoburn
              # qemu

              # extra tools
              fio
            ];
          }
        )
      ];
    };
}
