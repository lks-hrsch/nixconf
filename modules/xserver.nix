_: {
  flake.nixosModules.xserver =
    { lib, config, ... }:
    {
      # Load driver for Xorg and Wayland
      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
