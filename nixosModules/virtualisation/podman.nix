{
  config,
  pkgs,
  lib,
  ...
}:
let
  feature = config.features.virtualisation.podman;
in
{
  # podman
  # https://mynixos.com/nixpkgs/options/virtualisation.podman
  # https://nixos.wiki/wiki/Podman
  config = lib.mkIf feature.enable {

    # Useful other development tools
    environment.systemPackages = with pkgs; [
      docker-compose # start group of containers for dev
      podman-compose # start group of containers for dev
    ];

    virtualisation = {
      containers = {
        enable = true;
      };
      podman = {
        enable = true;
        dockerCompat = true; # Enable Docker compatibility mode
        dockerSocket.enable = true; # Enable Docker socket for compatibility
      };
    };
  };

}
