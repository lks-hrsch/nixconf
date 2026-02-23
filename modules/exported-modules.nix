_:
{
  flake.nixosModules = {
    default =
      { inputs, ... }:
      {
        imports = [
          ./_nixos
          inputs.sops-nix.nixosModules.sops
          inputs.quadlet-nix.nixosModules.quadlet
        ];
      };
  };

  flake.homeManagerModules.linux = ./_homeManager/linux;
}
