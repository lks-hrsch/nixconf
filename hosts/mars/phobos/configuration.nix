{ config, ... }:
{
  configurations.nixos."phobos".module =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        marsLxcBase
      ];

      networking.hostName = "phobos";
      marsLxc.ip = "192.168.1.12/24";
    };
}
