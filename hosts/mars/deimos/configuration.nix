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

      hardware.facter.reportPath =
        if builtins.pathExists ./facter.json then
          ./facter.json
        else
          throw "Missing hosts/mars/deimos/facter.json. Run: ssh root@192.168.1.13 'nix run github:numtide/nixos-facter -- -o /dev/stdout' > hosts/mars/deimos/facter.json";

      networking.hostName = "deimos";
      marsLxc.ip = "192.168.1.13/24";
    };
}
