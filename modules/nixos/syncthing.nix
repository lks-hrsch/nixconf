{ config, ... }:
{
  flake.modules.nixos.syncthing =
    _:
    let
      homeDir = config.flake.users.owner.home.nixos;
    in
    {
      services.syncthing = {
        enable = true;

        openDefaultPorts = true;
        overrideDevices = true;
        overrideFolders = true;

        user = config.flake.users.owner.username;
        dataDir = homeDir;
        configDir = "${homeDir}/.config/syncthing";

        settings = import ../../secrets/syncthing-settings.nix {
          inherit homeDir;
        };
      };
    };
}
