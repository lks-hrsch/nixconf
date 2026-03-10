{ inputs, self, ... }:
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
          self.outputs.modules.homeManager.base
          self.outputs.modules.homeManager.desktop-base
          self.outputs.modules.homeManager.desktop-apps-obsstudio
          self.outputs.modules.homeManager.desktop-apps-thunderbird
          self.outputs.modules.homeManager.desktop-hyprland-uwsm-env
          self.outputs.modules.homeManager.desktop-hyprland-cliphist
          self.outputs.modules.homeManager.desktop-hyprland-dunst
          self.outputs.modules.homeManager.desktop-hyprland-hypridle
          self.outputs.modules.homeManager.desktop-hyprland-hyprland
          self.outputs.modules.homeManager.desktop-hyprland-hyprlock
          self.outputs.modules.homeManager.desktop-hyprland-hyprpaper
          self.outputs.modules.homeManager.desktop-hyprland-hyprpolkitagent
          self.outputs.modules.homeManager.desktop-hyprland-rofi
          self.outputs.modules.homeManager.desktop-hyprland-waybar

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
