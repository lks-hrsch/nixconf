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
    hyprland = {
      # >= v0.55.4 required: fixes SEGV when the last monitor disconnects
      # (DPMS-off on DP drops the link), hyprwm/Hyprland#15048. That backport is
      # a symptom fix (null guard); the root-cause unsafe-state/fallback refactor
      # is hyprwm/Hyprland#14547 (main only).
      # TODO(next hyprland release): bump to the release containing #14547 and
      # re-run the DPMS reproducer: hyprctl dispatch dpms off; sleep 90; dpms on.
      url = "github:hyprwm/Hyprland/v0.55.4";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      imports = [ inputs.flake-parts.flakeModules.modules ] ++ moduleTree.imports ++ hostTree.imports;

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
