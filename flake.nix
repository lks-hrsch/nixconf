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
      custom-overlays = import ./overlays { inherit nixpkgs-unstable; };
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
        "lkshrsch-mbp-m3" =
          let
            system = "aarch64-darwin";
            nixPkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [
                nix-vscode-extensions.overlays.default
                custom-overlays.unstable
              ];
            };
          in
          nix-darwin.lib.darwinSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit self inputs constants; };
            modules = [
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
                    inherit inputs nixPkgs;
                    firefox-addons-allow-unfree = nixPkgs.callPackage firefox-addons { };
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
        "workstation-nixos" =
          let
            system = "x86_64-linux";
            nixPkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
              };
              overlays = [
                nix-vscode-extensions.overlays.default
                custom-overlays.unstable
              ];
            };
          in
          nixpkgs.lib.nixosSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit inputs constants; };
            modules = [
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
                    inherit inputs nixPkgs;
                    firefox-addons-allow-unfree = nixPkgs.callPackage firefox-addons { };
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
