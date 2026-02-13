# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  pkgs,
  inputs,
  ...
}:
let
  nv-fan-control = import ./nv-fan-control.nix { inherit pkgs; };
in
{
  imports = [
    inputs.self.outputs.modules.nixos.default
    inputs.self.nixosModules.features
    inputs.self.nixosModules.users
    inputs.self.nixosModules.time
    inputs.self.nixosModules.sops
    inputs.self.nixosModules.shell
    inputs.self.nixosModules.ssh
    inputs.self.nixosModules.nixvim
    inputs.self.nixosModules.tmux
    inputs.self.nixosModules.zsh
    inputs.self.nixosModules."1password"

    # vpn
    ./vpn.nix

    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

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
    hostName = "workstation-nixos"; # Define your hostname.
    hostId = "99c58a86"; # head -c 8 /etc/machine-id
    useNetworkd = true;
    # Pick only one of the below networking options.
    # wireless.enable = true; # Enables wireless support via wpa_supplicant.
    wireless.iwd.enable = true; # Enables wireless support via iwd.
    # networkmanager.enable = true; # Easiest to use and most distros use this by default.
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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # https://discourse.nixos.org/t/how-to-automatically-mount-external-hard-drive/15563
  # https://www.reddit.com/r/NixOS/comments/185f0x4/how_to_mount_a_usb_drive/
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # https://mynixos.com/nixpkgs/option/services.upower.enable
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  systemd.services.nvidia-fan-startup = {
    description = "Set NVIDIA Fan Speed at Startup";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${nv-fan-control}/bin/nv-fan-control 55";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system = {
    stateVersion = "24.11"; # Did you read the comment?
  };
}
