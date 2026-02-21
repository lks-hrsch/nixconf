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
    };
  };

  config = {
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
