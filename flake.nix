{
  description = "lkshrsch's configurations for nix-darwin and nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:lks-hrsch/nixos-hardware/master";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    # Deliberately NOT following our nixpkgs: mac-app-util is a Common Lisp
    # tool whose sbcl/fare-quasiquote dependency stack fails to build on
    # nixpkgs 26.05 aarch64-darwin — it needs the older nixpkgs it pins.
    mac-app-util.url = "github:hraban/mac-app-util";
    meridian = {
      url = "github:rynfar/meridian";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      moduleTree = inputs.import-tree ./modules;
      hostTree = inputs.import-tree ./hosts;
      overlays = import ./overlays { inherit inputs; };
      constants = import ./secrets/constants.nix;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        moduleTree
        hostTree
      ];

      options.repo = {
        constants = inputs.nixpkgs.lib.mkOption {
          type = inputs.nixpkgs.lib.types.raw;
          readOnly = true;
        };

        overlays = inputs.nixpkgs.lib.mkOption {
          type = inputs.nixpkgs.lib.types.lazyAttrsOf inputs.nixpkgs.lib.types.raw;
          readOnly = true;
        };
      };

      config = {
        repo.constants = constants;
        repo.overlays = overlays;
      };
    };
}
