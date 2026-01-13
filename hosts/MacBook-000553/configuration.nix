{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.outputs.modules.darwin.default
    inputs.self.outputs.modules.shared.default

    # vpn
    ./vpn.nix
  ];

  features = {
    desktop.enable = true;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
  };

  networking = {
    computerName = "MacBook-000553";
    hostName = "MacBook-000553";
    localHostName = "MacBook-000553";

    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };
  };

  # this will allow you to use nix-darwin with Determinate.
  nix.enable = false;

  system = {
    primaryUser = "lkshrsch";

    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null; # Set Git commit hash for darwin-version.
    stateVersion = 6; # $ darwin-rebuild changelog

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
      smb.NetBIOSName = "MacBook-000553";
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
        };
      };
    };
  };
}
