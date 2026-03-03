{ inputs, ... }:
{
  options = {
    flake = inputs.flake-parts.lib.mkSubmoduleOptions {
      nixosModules = inputs.nixpkgs.lib.mkOption {
        default = { };
      };
      darwinModules = inputs.nixpkgs.lib.mkOption {
        default = { };
      };
      homeManagerModules = inputs.nixpkgs.lib.mkOption {
        default = { };
      };
      darwinConfigurations = inputs.nixpkgs.lib.mkOption {
        type = inputs.nixpkgs.lib.types.lazyAttrsOf inputs.nixpkgs.lib.types.raw;
        default = { };
      };
      nixosConfigurations = inputs.nixpkgs.lib.mkOption {
        type = inputs.nixpkgs.lib.types.lazyAttrsOf inputs.nixpkgs.lib.types.raw;
        default = { };
      };
    };
  };

  config = {
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
