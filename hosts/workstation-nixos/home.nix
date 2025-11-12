{
  pkgs,
  lib,
  inputs,
  ...
}:
{

  imports = [
    inputs.self.outputs.modules.homeManager.default
    inputs.self.outputs.modules.homeManager.linux # Linux-specific modules
  ];

  home = {
    stateVersion = "24.11";
    homeDirectory = lib.mkDefault "/home/lkshrsch";
    username = "lkshrsch";

    packages = with pkgs; [
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

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
      font-awesome

      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/data/fonts/nerdfonts/shas.nix
      # (nerdfonts.override { fonts = [ "JetBrainsMono" "Meslo" "NerdFontsSymbolsOnly" "Noto" ]; })

      adwaita-icon-theme

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ];
  };
}
