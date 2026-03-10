{
  inputs,
  self,
  myLib,
  constants,
  custom-overlays,
  ...
}:
{
  flake.darwinConfigurations."lkshrsch-mb-pro-m1" = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        inputs
        constants
        custom-overlays
        ;
      lib = myLib;
    };
    modules = [
      self.darwinModules.hostlkshrsch-mb-pro-m1-configuration
    ];
  };

  flake.darwinModules.hostlkshrsch-mb-pro-m1-configuration =
    { lib, config, ... }:
    {
      imports = with config.flake.modules.darwin; [
        base
      ];

      networking = {
        computerName = "lkshrsch-mb-pro-m1";
        hostName = "lkshrsch-mb-pro-m1";
        localHostName = "lkshrsch-mb-pro-m1";
      };

      system.defaults.smb.NetBIOSName = "lkshrsch-mb-pro-m1";
    };
}
