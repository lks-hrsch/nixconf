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

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ];
  };
}
