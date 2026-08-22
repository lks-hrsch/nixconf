{ config, ... }:
{
  configurations.nixos."opportunity".module =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        marsLxcBase
      ];

      networking.hostName = "opportunity";
      marsLxc.ip = "192.168.1.15/24";
    };
}
