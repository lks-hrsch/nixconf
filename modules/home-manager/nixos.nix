{ config, inputs, ... }:
{
  flake.modules.nixos.homeManager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.stylix.homeModules.stylix
      ];
      extraSpecialArgs = { inherit inputs; };
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

        inputs.self.homeManagerModules.desktop-base
        inputs.self.homeManagerModules.desktop-apps-obsstudio
        inputs.self.homeManagerModules.desktop-apps-thunderbird
        inputs.self.homeManagerModules.desktop-hyprland-uwsm-env
        inputs.self.homeManagerModules.desktop-hyprland-cliphist
        inputs.self.homeManagerModules.desktop-hyprland-dunst
        inputs.self.homeManagerModules.desktop-hyprland-hypridle
        inputs.self.homeManagerModules.desktop-hyprland-hyprland
        inputs.self.homeManagerModules.desktop-hyprland-hyprlock
        inputs.self.homeManagerModules.desktop-hyprland-hyprpaper
        inputs.self.homeManagerModules.desktop-hyprland-hyprpolkitagent
        inputs.self.homeManagerModules.desktop-hyprland-rofi
        inputs.self.homeManagerModules.desktop-hyprland-waybar
      ];
    };
  };
}
