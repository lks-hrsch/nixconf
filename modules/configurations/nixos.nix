{
  inputs,
  config,
  lib,
  myLib,
  constants,
  custom-overlays,
  ...
}:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake.nixosConfigurations = lib.mapAttrs (
    _:
    { module }:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          constants
          custom-overlays
          ;
        lib = myLib;
      };
      modules = [ module ];
    }
  ) config.configurations.nixos;
}
