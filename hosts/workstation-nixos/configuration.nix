# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  # Nix settings
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true; # Automatically run garbage collection
      dates = "weekly"; # Run garbage collection weekly
      options = "--delete-older-than 21d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      trusted-users = [ "root" "lkshrsch" ];
      substituters = [ "https://cache.nixos.org/" "https://nix-community.cachix.org" "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  imports =
    [
      inputs.self.outputs.nixosModules.default

      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "workstation-nixos"; # Define your hostname.
    hostId = "99c58a86"; # head -c 8 /etc/machine-id
    useNetworkd = true;
    # Pick only one of the below networking options.
    # wireless.enable = true; # Enables wireless support via wpa_supplicant.
    wireless.iwd.enable = true; # Enables wireless support via iwd.
    # networkmanager.enable = true; # Easiest to use and most distros use this by default.
    firewall.allowedTCPPorts = [ 27040 ];
    firewall.extraCommands = ''iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns'';
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = "enp10s0";
        networkConfig = {
          DHCP = "yes";
        };
      };
      # "20-wlan" = {
      #   matchConfig.Name = "wlan0";
      #   networkConfig = {
      #     DHCP = "yes";
      #   };
      #   linkConfig.RequiredForOnline = "no";
      # };
    };
  };


  # Set your time zone.
  time.timeZone = "Europe/Berlin";

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

  # docker
  # https://nixos.wiki/wiki/Docker#GPU_Pass-through_.28Nvidia.29
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      daemon.settings.data-root = "/shared/docker";
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
      rocmPackages.rocm-smi
      rocmPackages.clr
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

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.games = { }; # Declare the "games" group.

  users.users.lkshrsch = {
    isNormalUser = true;
    home = "/home/lkshrsch";
    extraGroups = [ "wheel" "docker" "video" "games" ];
  };

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #   wget
    nixos-icons
    libva-utils # vainfo
    vulkan-tools # vulkaninfo, vkcube
    lm_sensors
    ffmpeg_6-full
    gnugrep
    dig
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

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
    autoUpgrade = {
      enable = true;
      # allowReboot  = true;
    };
  };
}

