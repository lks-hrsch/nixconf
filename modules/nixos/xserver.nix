_: {
  flake.modules.nixos.xserver =
    { lib, config, ... }:
    {
      # Load driver for Xorg and Wayland
      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
