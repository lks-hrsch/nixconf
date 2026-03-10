{ inputs, self, ... }:
{
  flake.modules.nixos.default =
    { ... }:
    {
      imports = [
        self.outputs.modules.nixos.avahi
        self.outputs.modules.nixos.flatpak
        self.outputs.modules.nixos.internationalisation
        self.outputs.modules.nixos.nixos-nix
        self.outputs.modules.nixos.pipewire
        self.outputs.modules.nixos.syncthing
        self.outputs.modules.nixos.xserver
        self.outputs.modules.nixos.zfs

        inputs.sops-nix.nixosModules.sops
        inputs.quadlet-nix.nixosModules.quadlet
      ];
    };
}
