{ config, inputs, ... }:
{
  flake.modules.nixos.homeManager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
        ];
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.${config.flake.users.owner.username}.imports = [
          (
            { lib, ... }:
            {
              home = {
                inherit (config.flake.users.owner) username;
                homeDirectory = lib.mkForce config.flake.users.owner.home.nixos;
                stateVersion = "25.05";
              };
            }
          )
          config.flake.modules.homeManager.base
          config.flake.modules.homeManager.desktop
        ];
      };
    };
}
