{
  description = "lkshrsch's NixOL configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-24.11";
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
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
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
    {
      darwinConfigurations = {
        "lkshrsch-mbp-m3" =
          let
            system = "aarch64-darwin";
            constants = import ./secrets/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [
                nix-vscode-extensions.overlays.default
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
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
                    stylix.homeManagerModules.stylix
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
            constants = import ./secrets/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
                rocmSupport = true;
              };
              overlays = [
                nix-vscode-extensions.overlays.default
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
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
                    stylix.homeManagerModules.stylix
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

        "phobos" =
          let
            system = "x86_64-linux";
            constants = import ./lib/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
              ];
            };
          in
          nixpkgs.lib.nixosSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit inputs constants; };
            modules = [
              ./hosts/mars/phobos/configuration.nix
              sops-nix.nixosModules.sops
            ];
          };

        "deimos" =
          let
            system = "x86_64-linux";
            constants = import ./lib/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
              ];
            };
          in
          nixpkgs.lib.nixosSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit inputs constants; };
            modules = [
              ./hosts/mars/deimos/configuration.nix
              sops-nix.nixosModules.sops
              quadlet-nix.nixosModules.quadlet
            ];
          };

        "curiosity" =
          let
            system = "x86_64-linux";
            constants = import ./lib/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
              ];
            };
          in
          nixpkgs.lib.nixosSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit inputs constants; };
            modules = [
              ./hosts/mars/curiosity/configuration.nix
              sops-nix.nixosModules.sops
            ];
          };

        "opportunity" =
          let
            system = "x86_64-linux";
            constants = import ./lib/constants.nix;
            nixPkgs = import nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config = prev.config;
                  };
                })
              ];
            };
          in
          nixpkgs.lib.nixosSystem {
            pkgs = nixPkgs;
            specialArgs = { inherit inputs constants; };
            modules = [
              ./hosts/mars/opportunity/configuration.nix
              sops-nix.nixosModules.sops
            ];
          };
      };

      nixosModules.default = ./nixosModules;
      darwinModules.default = ./modules/darwin;
      homeManagerModules = {
        default = ./modules/homeManager;
        linux = ./modules/homeManager/linux;
      };
    };
}
