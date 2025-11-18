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
    let
      system = "x86_64-linux";
      nixPkgs = import nixpkgs {
        inherit system;
        overlays = [ custom-overlays.unstable ];
      };
    in
    nixpkgs.lib.nixosSystem {
      pkgs = nixPkgs;
      specialArgs = { inherit inputs constants; };
      modules = [
        ../hosts/mars/${hostname}/configuration.nix
        sops-nix.nixosModules.sops
      ]
      ++ extraModules;
    };
}
