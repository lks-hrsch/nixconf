{
  nixpkgs,
  custom-overlays,
  sops-nix,
  inputs,
  constants,
}:
let
  lib = nixpkgs.lib;

  myLib = lib // {
    mkNixOSServer = import ./mkNixOSServer.nix {
      inherit
        lib
        inputs
        constants
        custom-overlays
        sops-nix
        myLib
        ;
    };

    mkWGInterface = import ./mkWGInterface.nix { inherit lib; };
  };
in
myLib
