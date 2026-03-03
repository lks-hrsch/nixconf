{
  inputs,
  self,
  myLib,
  constants,
  custom-overlays,
  ...
}:
{
  flake.darwinConfigurations."lkshrsch-mb-pro-m1" = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        constants
        custom-overlays
        ;
      lib = myLib;
    };
    modules = [
      self.darwinModules.hostlkshrsch-mb-pro-m1-configuration
    ];
  };

  flake.darwinModules.hostlkshrsch-mb-pro-m1-configuration =
    { lib, ... }:
    {
      imports = [
        self.darwinModules."1password"
        self.darwinModules.features
        self.darwinModules.firefox
        self.darwinModules.homebrew
        self.darwinModules.users
        self.darwinModules.time
        self.darwinModules.sops
        self.darwinModules.shell
        self.darwinModules.ssh
        self.darwinModules.zsh
        self.darwinModules.tmux

        inputs.sops-nix.darwinModules.sops
        inputs.mac-app-util.darwinModules.default
        inputs.nixvim.nixDarwinModules.nixvim
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.mac-app-util.homeManagerModules.default
              inputs.stylix.homeModules.stylix
            ];
            extraSpecialArgs = {
              inherit inputs;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = ".backup";
            users.lkshrsch = {
              imports = [
                self.homeManagerModules.hostlkshrsch-mb-pro-m1-home
              ];
            };
          };
        }
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

      features = {
        desktop.enable = true;
      };

      security.pam.services.sudo_local = {
        touchIdAuth = true;
        watchIdAuth = true;
      };

      networking = {
        computerName = "lkshrsch-mb-pro-m1";
        hostName = "lkshrsch-mb-pro-m1";
        localHostName = "lkshrsch-mb-pro-m1";

        applicationFirewall = {
          enable = true;
          enableStealthMode = true;
        };
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
          smb.NetBIOSName = "lkshrsch-mb-pro-m1";
          CustomUserPreferences = {
            "com.apple.desktopservices" = {
              DSDontWriteNetworkStores = true;
            };
          };
        };
      };
    };
}
