{ config, ... }:
let
  inherit (config.flake.users.owner) username;
in
{
  flake = {
    modules = {
      nixos.netbird =
        { pkgs, ... }:
        {
          networking.nftables.enable = true; # netbird needs nftables

          services.netbird = {
            # Set this to true if you want the GUI client
            package = pkgs.unstable.netbird;
            ui.enable = false;
            clients.wt0 = {
              # Port used to listen to wireguard connections
              port = 51822;
              environment = {
                NB_MANAGEMENT_URL = "https://netbird.lukashirsch.de";
              };
            };
          };

          # netbird creates the client's group as "netbird-<name>" (services/networking/netbird.nix).
          users.users.${username}.extraGroups = [ "netbird-wt0" ];
        };

      darwin.netbird = _: {
        # sudo netbird service install
        # sudo netbird service start
        # netbird up --management-url https://netbird.lukashirsch.de
        homebrew = {
          taps = [
            "netbirdio/tap"
          ];
          brews = [
            "netbirdio/tap/netbird"
          ];
          casks = [
            "netbirdio/tap/netbird-ui"
          ];
        };
      };
    };
  };
}
