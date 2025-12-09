{
  nixpkgs,
  custom-overlays,
  sops-nix,
  inputs,
  constants,
}:
let
  lib = nixpkgs.lib;
in
lib
// {
  mkNixOSServer =
    {
      hostname,
      extraModules ? [ ],
    }:
    lib.nixosSystem {
      specialArgs = { inherit inputs constants; };
      modules = [
        {
          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
          nixpkgs.overlays = [ custom-overlays.unstable ];
        }
        ../hosts/mars/${hostname}/configuration.nix
        sops-nix.nixosModules.sops
      ]
      ++ extraModules;
    };
}
