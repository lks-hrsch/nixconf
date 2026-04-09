_:
let
  timezone = "Europe/Berlin";
in
{
  flake.modules = {
    nixos.time = {
      time.timeZone = timezone;
    };

    darwin.time = {
      time.timeZone = timezone;
    };
  };
}
