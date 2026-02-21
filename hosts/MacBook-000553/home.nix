{ self, ... }:
{
  flake.homeManagerModules.hostMacBook-home =
    { lib, ... }:
    {
      imports = [
        self.homeManagerModules.default
      ];

      home = {
        stateVersion = "25.05";
        homeDirectory = lib.mkForce "/Users/lkshrsch";
        username = "lkshrsch";
      };
    };
}
