_: {
  flake.nixosModules.xserver =
    { lib, config, ... }:
    {
      config = lib.mkIf config.features.desktop.enable {
        # Load driver for Xorg and Wayland
        services.xserver.videoDrivers = [ "nvidia" ];
      };
    };
}
