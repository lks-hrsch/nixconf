{ ... }:
{
  # Load driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
}
