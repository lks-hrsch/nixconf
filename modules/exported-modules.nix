{ inputs, config, ... }:
{
  flake.modules.nixos.default.imports = [
    config.flake.modules.nixos.avahi
    config.flake.modules.nixos.flatpak
    config.flake.modules.nixos.internationalisation
    config.flake.modules.nixos.nixos-nix
    config.flake.modules.nixos.pipewire
    config.flake.modules.nixos.syncthing
    config.flake.modules.nixos.xserver
    config.flake.modules.nixos.zfs

    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet
  ];
}
