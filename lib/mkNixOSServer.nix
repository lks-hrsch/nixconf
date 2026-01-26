{
  lib,
  inputs,
  constants,
  custom-overlays,
  sops-nix,
  myLib,
}:
{
  hostname,
  extraModules ? [ ],
}:
lib.nixosSystem {
  specialArgs = {
    inherit inputs constants;
    lib = myLib;
  };
  modules = [
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      nixpkgs.overlays = [ custom-overlays.unstable ];
    }
    ../hosts/mars/${hostname}/configuration.nix
    sops-nix.nixosModules.sops
    inputs.nixvim.nixosModules.nixvim
  ]
  ++ extraModules;
}
