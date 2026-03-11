{
  inputs,
  config,
  lib,
  ...
}:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake.darwinConfigurations = lib.mapAttrs (
    _:
    { module }:
    inputs.nix-darwin.lib.darwinSystem {
      modules = [ module ];
    }
  ) config.configurations.darwin;
}
