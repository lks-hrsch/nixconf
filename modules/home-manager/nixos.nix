{ config, inputs, ... }:
{
  flake.modules.nixos.homeManager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
        ];
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = ".backup";
        users.lkshrsch.imports = [
          (
            { lib, ... }:
            {
              home = {
                username = "lkshrsch";
                homeDirectory = lib.mkForce "/home/lkshrsch";
                stateVersion = "25.05";
              };
            }
          )
          config.flake.modules.homeManager.base
          config.flake.modules.homeManager.desktop-base
          config.flake.modules.homeManager.desktop-apps-obsstudio
          config.flake.modules.homeManager.desktop-apps-thunderbird
          config.flake.modules.homeManager.desktop-hyprland-uwsm-env
          config.flake.modules.homeManager.desktop-hyprland-cliphist
          config.flake.modules.homeManager.desktop-hyprland-dunst
          config.flake.modules.homeManager.desktop-hyprland-hypridle
          config.flake.modules.homeManager.desktop-hyprland-hyprland
          config.flake.modules.homeManager.desktop-hyprland-hyprlock
          config.flake.modules.homeManager.desktop-hyprland-hyprpaper
          config.flake.modules.homeManager.desktop-hyprland-hyprpolkitagent
          config.flake.modules.homeManager.desktop-hyprland-rofi
          config.flake.modules.homeManager.desktop-hyprland-waybar

          (
            { pkgs, ... }:
            {
              home.packages = with pkgs; [
                nautilus
                pavucontrol
                pkg-config
                rustdesk
                osu-lazer
                gimp3

                # some dependencies
                gtk3
                qt5.qtbase

                # dev tools
                nasm # nasm compiler
                gnumake # GNU make
                cmake
                ninja
                clang
                clang-tools

                # cudatoolkit
                linuxPackages.nvidia_x11

                # dev virtualization
                grub2
                libisoburn
                qemu

                # extra tools
                fio
              ];
            }
          )
        ];
      };
    };
}
