{ ... }:
{
  flake = {
    nixosModules.time = {
      time.timeZone = "Europe/Berlin";
    };

    darwinModules.time = {
      time.timeZone = "Europe/Berlin";
    };
  };
}
