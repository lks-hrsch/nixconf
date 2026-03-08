_: {
  flake.nixosModules = {
    default =
      { inputs, ... }:
      {
        imports = [
          inputs.self.nixosModules.avahi
          inputs.self.nixosModules.flatpak
          inputs.self.nixosModules.internationalisation
          inputs.self.nixosModules.nixos-nix
          inputs.self.nixosModules.pipewire
          inputs.self.nixosModules.syncthing
          inputs.self.nixosModules.xserver
          inputs.self.nixosModules.zfs
          inputs.sops-nix.nixosModules.sops
          inputs.quadlet-nix.nixosModules.quadlet
        ];
      };
  };

}
