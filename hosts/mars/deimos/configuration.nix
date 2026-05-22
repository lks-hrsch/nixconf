{ config, ... }:
{
  configurations.nixos."deimos".module =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        podman
        netbird
        alloy
        marsLxcBase
      ];

      networking.hostName = "deimos";
      marsLxc.ip = "192.168.1.13/24";
    };
}
