{
  inputs,
  self,
  myLib,
  constants,
  custom-overlays,
  ...
}:
{
  flake.darwinConfigurations."MacBook-000553" = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        inputs
        constants
        custom-overlays
        ;
      lib = myLib;
    };
    modules = [
      self.darwinModules.hostMacBook-configuration
      self.darwinModules.hostMacBook-vpn
    ];
  };

  flake.darwinModules.hostMacBook-configuration =
    { lib, ... }:
    {
      imports = with self.darwinModules; [
        base
        podman
        work
      ];

      networking = {
        computerName = "MacBook-000553";
        hostName = "MacBook-000553";
        localHostName = "MacBook-000553";
      };

      system.defaults.smb.NetBIOSName = "MacBook-000553";
    };
}
