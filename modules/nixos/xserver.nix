_: {
  flake.modules.nixos.xserver = _: {
    # Load driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
