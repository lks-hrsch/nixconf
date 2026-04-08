{ config, ... }:
{
  configurations.darwin."MacBook-000553".module =
    { ... }:
    {
      imports = with config.flake.modules.darwin; [
        base
        podman
        netbird
        work
      ];

      networking.hostName = "MacBook-000553";
    };
}
