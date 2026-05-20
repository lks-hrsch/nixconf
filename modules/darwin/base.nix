{
  config,
  self,
  inputs,
  ...
}:
let
  inherit (config.repo) overlays;
  revision = self.rev or self.dirtyRev or null;
in
{
  flake.modules.darwin.base =
    { ... }:
    {
      imports = [
        config.flake.modules.darwin.onepassword
        config.flake.modules.darwin.firefox
        config.flake.modules.darwin.homebrew
        config.flake.modules.darwin.nixvim
        config.flake.modules.darwin.time
        config.flake.modules.darwin.users
        config.flake.modules.darwin.sops
        config.flake.modules.darwin.ssh
        config.flake.modules.darwin.zsh

        config.flake.modules.darwin.homeManager

        inputs.mac-app-util.darwinModules.default
        inputs.nixvim.nixDarwinModules.nixvim
        inputs.sops-nix.darwinModules.sops
      ]
      ++ [
        (
          { config, lib, ... }:
          {
            nixpkgs = {
              hostPlatform = "aarch64-darwin";
              config.allowUnfree = true;
              overlays = [
                overlays.unstable
                overlays.firefox-addons
                overlays.nix-vscode-extensions
              ];
            };

            security.pam.services.sudo_local = {
              touchIdAuth = true;
              watchIdAuth = true;
            };

            networking = {
              applicationFirewall = {
                enable = true;
                enableStealthMode = true;
              };

              computerName = lib.mkDefault config.networking.hostName;
              localHostName = lib.mkDefault config.networking.hostName;
            };

            # this will allow you to use nix-darwin with Determinate.
            nix.enable = false;

            system = {
              configurationRevision = revision;
              stateVersion = 6;

              defaults = {
                CustomUserPreferences = {
                  "com.apple.desktopservices" = {
                    DSDontWriteNetworkStores = true;
                  };
                };
                dock.expose-group-apps = true;
                finder = {
                  AppleShowAllFiles = true;
                  AppleShowAllExtensions = true;
                  FXEnableExtensionChangeWarning = false;
                  FXPreferredViewStyle = "Nlsv";
                  FXRemoveOldTrashItems = true;
                  ShowPathbar = true;
                };
                loginwindow = {
                  DisableConsoleAccess = true;
                  GuestEnabled = false;
                };
                NSGlobalDomain = {
                  AppleInterfaceStyle = "Dark";
                  AppleMeasurementUnits = "Centimeters";
                  AppleShowAllExtensions = true;
                  AppleShowAllFiles = true;
                  AppleShowScrollBars = "WhenScrolling";
                  AppleTemperatureUnit = "Celsius";
                  _HIHideMenuBar = false;
                };
                spaces.spans-displays = false;
                smb.NetBIOSName = lib.mkDefault config.networking.hostName;
                universalaccess.reduceMotion = true;
              };
            };
          }
        )
      ];
    };
}
