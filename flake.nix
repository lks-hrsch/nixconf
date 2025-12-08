{
  description = "lkshrsch's configurations for nix-darwin and nixos";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.52.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix"; # https://github.com/hraban/mac-app-util/issues/39#issuecomment-3503946041
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-darwin,
      home-manager,
      stylix,
      firefox-addons,
      nix-vscode-extensions,
      sops-nix,
      quadlet-nix,
      mac-app-util,
      ...
    }@inputs:
    let
      custom-overlays = import ./overlays { inherit inputs; };
      constants = import ./secrets/constants.nix;
      lib = import ./lib {
        inherit
          nixpkgs
          custom-overlays
          sops-nix
          inputs
          constants
          ;
      };
    in
    {
      darwinConfigurations = {
        "lkshrsch-mbp-m3" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit self inputs constants; };
          modules = [
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                nix-vscode-extensions.overlays.default
                custom-overlays.unstable
                custom-overlays.firefox-addons
              ];
            }
            ./hosts/lkshrsch-mbp-m3/configuration.nix
            sops-nix.darwinModules.sops
            mac-app-util.darwinModules.default

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  mac-app-util.homeManagerModules.default
                  stylix.homeModules.stylix
                ];
                extraSpecialArgs = {
                  inherit inputs;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = ".backup";
                users.lkshrsch = {
                  imports = [
                    ./hosts/lkshrsch-mbp-m3/home.nix
                  ];
                };
              };
            }
          ];
        };
      };

      nixosConfigurations = {
        "workstation-nixos" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs constants; };
          modules = [
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.config = {
                allowUnfree = true;
                cudaSupport = true;
              };
              nixpkgs.overlays = [
                nix-vscode-extensions.overlays.default
                custom-overlays.unstable
                custom-overlays.firefox-addons
              ];
            }
            ./hosts/workstation-nixos/configuration.nix
            sops-nix.nixosModules.sops
            quadlet-nix.nixosModules.quadlet

            # make home-manager as a module of nixos
            # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  stylix.homeModules.stylix
                ];
                extraSpecialArgs = {
                  inherit inputs;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = ".backup";
                users.lkshrsch = {
                  imports = [
                    ./hosts/workstation-nixos/home.nix

                  ];
                };
              };
            }
          ];
        };

        "phobos" = lib.mkNixOSServer {
          hostname = "phobos";
        };

        "deimos" = lib.mkNixOSServer {
          hostname = "deimos";
          extraModules = [
            quadlet-nix.nixosModules.quadlet
          ];
        };

        "curiosity" = lib.mkNixOSServer {
          hostname = "curiosity";
        };

        "opportunity" = lib.mkNixOSServer {
          hostname = "opportunity";
        };
      };

      # module decalrations
      modules = {
        nixos.default = ./modules/nixos;
        darwin.default = ./modules/darwin;
        shared.default = ./modules/shared;
        homeManager = {
          default = ./modules/homeManager;
          linux = ./modules/homeManager/linux;
        };
      };
    };
}
