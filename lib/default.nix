{
  nixpkgs,
  custom-overlays,
  sops-nix,
  inputs,
  constants,
}:
let
  inherit (nixpkgs) lib;

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
