{ config, inputs, ... }:
{
  flake.modules.darwin.homeManager =
    { ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      home-manager = {
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.mac-app-util.homeManagerModules.default
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
                homeDirectory = lib.mkForce config.flake.users.owner.home.darwin;
                stateVersion = "25.05";
              };
            }
          )
          config.flake.modules.homeManager.base
        ];
      };
    };
}
