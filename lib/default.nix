{
  nixpkgs,
  custom-overlays,
  sops-nix,
  inputs,
  constants,
}:

{
  mkNixOSServer =
    {
      hostname,
      extraModules ? [ ],
    }:
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs constants; };
      modules = [
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.overlays = [ custom-overlays.unstable ];
        }
        ../hosts/mars/${hostname}/configuration.nix
        sops-nix.nixosModules.sops
      ]
      ++ extraModules;
    };
}
