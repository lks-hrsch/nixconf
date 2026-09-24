{ config, ... }:
{
  configurations.nixos."deimos".module =
    _:
    let
      ip = "192.168.1.13";
    in
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
          throw "Missing hosts/mars/deimos/facter.json. Run: ssh root@${ip} 'nix run github:numtide/nixos-facter -- -o /dev/stdout' > hosts/mars/deimos/facter.json";

      networking.hostName = "deimos";
      marsLxc.ip = "${ip}/24";
    };
}
