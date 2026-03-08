{
  inputs,
  self,
  config,
  myLib,
  constants,
  custom-overlays,
  ...
}:
{
  flake.nixosConfigurations."workstation-nixos" = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit
        inputs
        constants
        custom-overlays
        ;
      lib = myLib;
    };
    modules = [
      self.nixosModules.hostworkstation-nixos-configuration
      self.nixosModules.hostworkstation-nixos-vpn
    ];
  };

  flake.nixosModules.hostworkstation-nixos-configuration =
    { pkgs, ... }:
    let
      nv-fan-control = import ./_nv-fan-control.nix { inherit pkgs; };
    in
    {
      imports = [
        self.nixosModules.default
        self.nixosModules.features
        self.nixosModules.users
        self.nixosModules.time
        self.nixosModules.podman
        self.nixosModules.sops
        self.nixosModules.shell
        self.nixosModules.ssh
        self.nixosModules.nixvim
        self.nixosModules.tmux
        self.nixosModules.zsh
        self.nixosModules."1password"

        inputs.self.nixosModules.desktop-hyprland

        inputs.nixvim.nixosModules.nixvim

        config.flake.modules.nixos.homeManager

        # Include the results of the hardware scan.
        ./_home-nas-mounts.nix
        ./_hardware-configuration.nix
      ];

      nixpkgs = {
        hostPlatform = "x86_64-linux";
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
        overlays = [
          self.outputs.custom-overlays.unstable
          self.outputs.custom-overlays.firefox-addons
          self.outputs.custom-overlays.nix-vscode-extensions
        ];
      };

      features = {
        desktop.enable = true;
        gaming.enable = true;
        virtualisation.podman.enable = true;
        zfs.enable = true;
        nas.enable = true;
      };

      # Use the systemd-boot EFI boot loader.
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking = {
        hostName = "workstation-nixos";
        hostId = "99c58a86"; # head -c 8 /etc/machine-id
        useNetworkd = true;
        wireless.iwd.enable = true;
        firewall.allowedTCPPorts = [ 27040 ];
        firewall.extraCommands = "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";
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
              IPv6AcceptRA = true;
            };
          };
          "20-wlan" = {
            matchConfig.Name = "wlan0";
            networkConfig = {
              DHCP = "no";
              Address = "192.168.1.41/24";
              Gateway = "192.168.1.1";
              DNS = [ "192.168.1.1" ];
              IPv6AcceptRA = true;
            };
            linkConfig.RequiredForOnline = "no";
          };
        };
      };

      hardware.nvidia-container-toolkit.enable = true;

      # Enable OpenGL
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva
          vulkan-loader
        ];
      };

      hardware.nvidia = {
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

      services.devmon.enable = true;
      services.gvfs.enable = true;
      services.udisks2.enable = true;
      services.upower.enable = true;

      hardware.opentabletdriver = {
        enable = true;
        daemon.enable = true;
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

      system = {
        configurationRevision = self.rev or self.dirtyRev or null;
        stateVersion = "24.11";
      };
    };
}
