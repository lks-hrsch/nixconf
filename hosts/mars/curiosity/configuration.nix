{ config, ... }:
{
  configurations.nixos."curiosity".module =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        marsLxcBase
      ];

      networking.hostName = "curiosity";
      marsLxc.ip = "192.168.1.14/24";
    };
}
