{ config, ... }:
{
  configurations.nixos."phobos".module =
    _:
    let
      ip = "192.168.1.12";
    in
    {
      imports = with config.flake.modules.nixos; [
        base
        podman
        netbird
        server
        marsLxcBase
      ];

      hardware.facter.reportPath =
        if builtins.pathExists ./facter.json then
          ./facter.json
        else
          throw "Missing hosts/mars/phobos/facter.json. Run: ssh root@${ip} 'nix run github:numtide/nixos-facter -- -o /dev/stdout' > hosts/mars/phobos/facter.json";

      # uid matches the TrueNAS user `openvad` (userns_idmap DIRECT), so files
      # it owns on the NAS show up as openvad inside this LXC.
      users.users.openvad = {
        isNormalUser = true;
        uid = 3005;
        group = "users";
        openssh.authorizedKeys.keys = [ config.repo.constants.sshPublicKey ];
      };

      networking.hostName = "phobos";
      marsLxc.ip = "${ip}/24";
    };
}
