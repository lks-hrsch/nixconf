{ config, lib, ... }:
{
  options.flake.users = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  config = {
    flake.modules.nixos.users =
      { ... }:
      {
        imports = [
          config.flake.modules.nixos."users-owner"
          config.flake.modules.nixos."users-apps"
          config.flake.modules.nixos."users-games"
          config.flake.modules.nixos."users-renderer"
          config.flake.modules.nixos."users-video"
        ];
      };

    flake.modules.darwin.users =
      { ... }:
      {
        imports = [
          config.flake.modules.darwin."users-owner"
          config.flake.modules.darwin."users-apps"
        ];
      };
  };
}
