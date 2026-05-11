{ config, ... }:
{
  configurations.nixos."workstation-nixos".module =
    { pkgs, ... }:
    let
      nv-fan-control = import ./_nv-fan-control.nix { inherit pkgs; };
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
        xserver
        zfs
        syncthing
        desktop
        desktop-hyprland
        gaming
        homeManager
      ];

      nixpkgs.config.cudaSupport = true;

      networking = {
        hostName = "workstation-nixos";
        hostId = "99c58a86"; # head -c 8 /etc/machine-id
        useNetworkd = true;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
        firewall.allowedTCPPorts = [ 27040 ];
      };

      systemd.network = {
        enable = true;
        networks = {
          "10-lan" = {
            matchConfig.Name = "enp10s0";
            networkConfig = {
              DHCP = "no";
              Address = "192.168.1.40/24";
              Gateway = "192.168.1.1";
              DNS = [ "192.168.1.1" ];
              Domains = "~mars.lukashirsch.de ~deimos.mars.lukashirsch.de";
              IPv6AcceptRA = true;
            };
          };
        };
      };

      hardware = {
        bluetooth.enable = true;

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

      # https://discourse.nixos.org/t/how-to-automatically-mount-external-hard-drive/15563
      # https://www.reddit.com/r/NixOS/comments/185f0x4/how_to_mount_a_usb_drive/
      # https://mynixos.com/nixpkgs/option/services.upower.enable
      services = {
        devmon.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;
        upower.enable = true;
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
      ];

      systemd.services.nvidia-fan-startup = {
        description = "Set NVIDIA Fan Speed at Startup";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${nv-fan-control}/bin/nv-fan-control 55";
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
    };
}
