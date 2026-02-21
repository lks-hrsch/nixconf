{ inputs, ... }:
let
  custom-overlays = import ../overlays { inherit inputs; };
  constants = import ../secrets/constants.nix;
  lib = import ../lib {
    inherit (inputs) nixpkgs sops-nix;
    inherit inputs custom-overlays constants;
  };
in
{
  _module.args = {
    inherit custom-overlays constants;
    myLib = lib;
  };

  flake = { inherit custom-overlays constants lib; };
}
