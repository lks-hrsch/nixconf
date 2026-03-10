{ inputs, self, ... }:
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
        extraSpecialArgs = { inherit inputs; };
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = ".backup";
        users.lkshrsch.imports = [
          (
            { lib, ... }:
            {
              home = {
                username = "lkshrsch";
                homeDirectory = lib.mkForce "/Users/lkshrsch";
                stateVersion = "25.05";
              };
            }
          )
          self.outputs.modules.homeManager.base
        ];
      };
    };
}
