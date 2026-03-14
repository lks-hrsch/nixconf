{ config, ... }:
{
  flake.modules.nixos.syncthing =
    { ... }:
    let
      homeDir = config.home.homeDirectory;
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
