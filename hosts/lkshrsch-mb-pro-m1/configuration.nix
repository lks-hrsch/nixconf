{ config, ... }:
{
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { ... }:
    {
      imports = with config.flake.modules.darwin; [
        base
      ];

      networking.hostName = "lkshrsch-mb-pro-m1";
    };
}
