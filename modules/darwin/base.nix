{
  self,
  config,
  inputs,
  ...
}:
{
  flake.darwinModules.base = {
    imports = [
      self.darwinModules."1password"
      self.darwinModules.firefox
      self.darwinModules.homebrew
      self.darwinModules.users
      self.darwinModules.time
      self.darwinModules.sops
      self.darwinModules.shell
      self.darwinModules.ssh
      self.darwinModules.zsh
      self.darwinModules.tmux

      config.flake.modules.darwin.homeManager
      inputs.mac-app-util.darwinModules.default
      inputs.nixvim.nixDarwinModules.nixvim
      inputs.sops-nix.darwinModules.sops
    ];

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      config.allowUnfree = true;
      overlays = [
        self.outputs.custom-overlays.unstable
        self.outputs.custom-overlays.firefox-addons
        self.outputs.custom-overlays.nix-vscode-extensions
      ];
    };

    security.pam.services.sudo_local = {
      touchIdAuth = true;
      watchIdAuth = true;
    };

    networking.applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };

    # this will allow you to use nix-darwin with Determinate.
    nix.enable = false;

    system = {
      primaryUser = "lkshrsch";

      configurationRevision = self.rev or self.dirtyRev or null;
      stateVersion = 6;

      defaults = {
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
        };
        CustomUserPreferences = {
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
          };
        };
      };
    };
  };
}
