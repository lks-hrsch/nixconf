{ ... }:
let
  username = "lkshrsch";
  homeDir = "/home/${username}";
in
{
  services.syncthing = {
    enable = true;

    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = true;

    user = "lkshrsch";
    dataDir = homeDir;
    configDir = "${homeDir}/.config/syncthing";

    settings = import ../../secrets/syncthing-settings.nix {
      inherit homeDir;
    };
  };
}
