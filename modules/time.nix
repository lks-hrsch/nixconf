_:
let
  timezone = "Europe/Berlin";
in
{
  flake = {
    nixosModules.time = {
      time.timeZone = timezone;
    };

    darwinModules.time = {
      time.timeZone = timezone;
    };
  };
}
