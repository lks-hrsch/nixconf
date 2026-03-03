{ self, ... }:
{
  flake.homeManagerModules.hostlkshrsch-mb-pro-m1-home =
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
