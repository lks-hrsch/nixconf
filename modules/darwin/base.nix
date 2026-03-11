{
  config,
  self,
  inputs,
  ...
}:
{
  flake.modules.darwin.base =
    { ... }:
    {
      imports = [
        config.flake.modules.darwin."1password"
        config.flake.modules.darwin.firefox
        config.flake.modules.darwin.homebrew
        config.flake.modules.darwin.nixvim
        config.flake.modules.darwin.users
        config.flake.modules.darwin.time
        config.flake.modules.darwin.sops
        config.flake.modules.darwin.ssh
        config.flake.modules.darwin.zsh

        config.flake.modules.darwin.homeManager

        inputs.mac-app-util.darwinModules.default
        inputs.nixvim.nixDarwinModules.nixvim
        inputs.sops-nix.darwinModules.sops
      ];

      nixpkgs = {
        hostPlatform = "aarch64-darwin";
        config.allowUnfree = true;
        overlays = [
          config.repo.overlays.unstable
          config.repo.overlays.firefox-addons
          config.repo.overlays.nix-vscode-extensions
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
