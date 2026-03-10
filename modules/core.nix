{ inputs, lib, ... }:
let
  custom-overlays = import ../overlays { inherit inputs; };
  constants = import ../secrets/constants.nix;
  myLib = import ../lib {
    inherit (inputs) nixpkgs sops-nix;
    inherit inputs custom-overlays constants;
  };
in
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    default = { };
  };

  config = {
    _module.args = {
      inherit custom-overlays constants myLib;
    };

    flake = {
      inherit custom-overlays constants;
      lib = myLib;
    };
  };
}
