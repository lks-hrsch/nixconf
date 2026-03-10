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
    mkWGInterface = import ./mkWGInterface.nix { inherit lib; };
  };
in
myLib
