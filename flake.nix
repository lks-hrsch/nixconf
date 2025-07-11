{
  description = "lkshrsch's NixOL configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
    hyprland = {
      url = "github:hyprwm/Hyprland";
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
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      stylix,
      firefox-addons,
      sops-nix,
      ...
    }@inputs:
    {
      nixosConfigurations."workstation-nixos" =
        let
          system = "x86_64-linux";
          nixPkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
              rocmSupport = true;
            };
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
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/workstation-nixos/configuration.nix
            sops-nix.nixosModules.sops

            # make home-manager as a module of nixos
            # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                sharedModules = [
                  sops-nix.homeManagerModules.sops
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
                    stylix.homeManagerModules.stylix
                    ./hosts/workstation-nixos/home.nix

                  ];
                };
              };
            }
          ];
        };

      nixosModules.default = ./nixosModules;
      homeManagerModules.default = ./homeManagerModules;
    };
}
