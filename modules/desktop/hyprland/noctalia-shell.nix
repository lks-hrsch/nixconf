{ inputs, ... }:
{
  flake.modules.homeManager.desktop-hyprland-noctalia-shell =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Configure Noctalia Shell with full settings from v4.7.5
      programs.noctalia-shell = {
        enable = true;

        settings = {
          # AppLauncher configuration
          appLauncher = {
            enableClipboardHistory = true;
            showCategories = false;
            terminalCommand = "uwsm app -- ghostty -e";
            density = "compact";
          };

          # Control Center configuration
          controlCenter = {
            cards = [
              {
                enabled = true;
                id = "profile-card";
              }
              {
                enabled = true;
                id = "shortcuts-card";
              }
              {
                enabled = true;
                id = "audio-card";
              }
              {
                enabled = true;
                id = "brightness-card";
              }
              {
                enabled = false;
                id = "weather-card";
              }
              {
                enabled = false;
                id = "media-sysmon-card";
              }
            ];
            shortcuts = {
              left = [ { id = "NightLight"; } ];
              right = [
                { id = "Bluetooth"; }
                { id = "WiFi"; }
              ];
            };
          };

          # Location configuration (Dresden, Germany)
          location = {
            name = "Dresden, Germany";
            showWeekNumberInCalendar = true;
            autoLocate = false;
          };

          # Night Light configuration
          nightLight = {
            enabled = true;
          };

          # Session menu (power options)
          sessionMenu = {
            countdownDuration = 10000;
            enableCountdown = true;
            largeButtonsLayout = "single-row";
            largeButtonsStyle = true;
            position = "center";
            powerOptions = [
              {
                action = "lock";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "1";
              }
              {
                action = "suspend";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "2";
              }
              {
                action = "hibernate";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "3";
              }
              {
                action = "reboot";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "4";
              }
              {
                action = "logout";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "5";
              }
              {
                action = "shutdown";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "6";
              }
              {
                action = "rebootToUefi";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "7";
              }
              {
                action = "userspaceReboot";
                command = "";
                countdownEnabled = true;
                enabled = false;
                keybind = "";
              }
            ];
            showHeader = true;
            showKeybinds = true;
          };

          # Settings version
          settingsVersion = 59;

          # System Monitor configuration
          systemMonitor = {
            enableDgpuMonitoring = true;
          };

          # Wallpaper configuration (replaces hyprpaper)
          wallpaper = {
            enabled = true;
            directory = "/etc/nixos/wallpaper";
          };

          # Bar configuration
          bar = {
            barType = "floating";
            monitors = [
              "DP-2"
              "DP-3"
            ];
            screenOverrides = [
              {
                enabled = false;
                name = "DP-3";
                widgets = null;
              }
              {
                enabled = true;
                name = "DP-2";
                widgets = {
                  center = [
                    {
                      characterCount = 2;
                      colorizeIcons = true;
                      emptyColor = "secondary";
                      enableScrollWheel = true;
                      focusedColor = "primary";
                      followFocusedScreen = false;
                      fontWeight = "bold";
                      groupedBorderOpacity = 1;
                      hideUnoccupied = false;
                      iconScale = 0.75;
                      id = "Workspace";
                      labelMode = "index";
                      occupiedColor = "secondary";
                      pillSize = 0.6;
                      showApplications = true;
                      showApplicationsHover = false;
                      showBadge = true;
                      showLabelsOnlyWhenOccupied = true;
                      unfocusedIconsOpacity = 0.5;
                    }
                  ];
                  left = [
                    {
                      compactMode = false;
                      hideMode = "visible";
                      hideWhenIdle = false;
                      id = "MediaMini";
                      maxWidth = 145;
                      panelShowAlbumArt = true;
                      scrollingMode = "hover";
                      showAlbumArt = true;
                      showArtistFirst = true;
                      showProgressRing = true;
                      showVisualizer = false;
                      textColor = "none";
                      useFixedWidth = false;
                      visualizerType = "linear";
                    }
                  ];
                  right = [
                    {
                      compactMode = false;
                      diskPath = "/";
                      iconColor = "none";
                      id = "SystemMonitor";
                      showCpuCores = false;
                      showCpuFreq = false;
                      showCpuTemp = true;
                      showCpuUsage = true;
                      showDiskAvailable = false;
                      showDiskUsage = false;
                      showDiskUsageAsPercent = false;
                      showGpuTemp = true;
                      showLoadAverage = false;
                      showMemoryAsPercent = false;
                      showMemoryUsage = true;
                      showNetworkStats = true;
                      showSwapUsage = false;
                      textColor = "none";
                      useMonospaceFont = true;
                      usePadding = true;
                    }
                  ];
                };
              }
            ];
            widgets = {
              left = [
                {
                  enableColorization = true;
                  useDistroLogo = true;
                  id = "ControlCenter";
                }
                {
                  defaultSettings = { };
                  id = "plugin:workspace-overview";
                }
                {
                  characterCount = 2;
                  colorizeIcons = true;
                  emptyColor = "secondary";
                  enableScrollWheel = true;
                  focusedColor = "primary";
                  followFocusedScreen = false;
                  fontWeight = "bold";
                  groupedBorderOpacity = 1;
                  hideUnoccupied = false;
                  iconScale = 0.75;
                  labelMode = "index";
                  occupiedColor = "secondary";
                  pillSize = 0.6;
                  showApplications = true;
                  showApplicationsHover = false;
                  showBadge = true;
                  showLabelsOnlyWhenOccupied = true;
                  unfocusedIconsOpacity = 0.5;
                  id = "Workspace";
                }
              ];
              center = [ ];
              right = [
                {
                  blacklist = [ ];
                  chevronColor = "none";
                  colorizeIcons = true;
                  drawerEnabled = true;
                  hidePassive = false;
                  pinned = [
                    "1Password"
                    "Fcitx"
                    "spotify-client"
                    "ibus-ui-gtk3"
                  ];
                  id = "Tray";
                }
                {
                  defaultSettings = {
                    activeColor = "primary";
                    enableToast = true;
                    hideInactive = false;
                    iconSpacing = 4;
                    inactiveColor = "none";
                    micFilterRegex = "";
                    removeMargins = false;
                  };
                  id = "plugin:privacy-indicator";
                }
                {
                  compactMode = false;
                  diskPath = "/";
                  iconColor = "none";
                  showCpuCores = false;
                  showCpuFreq = false;
                  showCpuTemp = true;
                  showCpuUsage = true;
                  showDiskAvailable = false;
                  showDiskUsage = false;
                  showDiskUsageAsPercent = false;
                  showGpuTemp = true;
                  showLoadAverage = false;
                  showMemoryAsPercent = false;
                  showMemoryUsage = true;
                  showNetworkStats = true;
                  showSwapUsage = false;
                  textColor = "none";
                  useMonospaceFont = true;
                  usePadding = true;
                  id = "SystemMonitor";
                }
                {
                  iconColor = "none";
                  textColor = "none";
                  id = "KeepAwake";
                }
                {
                  displayMode = "alwaysShow";
                  iconColor = "none";
                  middleClickCommand = "pwvucontrol || pavucontrol";
                  textColor = "none";
                  id = "Volume";
                }
                {
                  displayMode = "alwaysShow";
                  iconColor = "none";
                  id = "Microphone";
                  middleClickCommand = "pwvucontrol || pavucontrol";
                  textColor = "none";
                }
                {
                  hideWhenZero = false;
                  hideWhenZeroUnread = false;
                  iconColor = "none";
                  showUnreadBadge = true;
                  unreadBadgeColor = "primary";
                  id = "NotificationHistory";
                }
                {
                  clockColor = "none";
                  customFont = "";
                  formatHorizontal = "dddd, MMMM dd yyyy  HH:mm";
                  formatVertical = "HH mm - dd MM";
                  tooltipFormat = "dddd, MMMM dd yyyy  HH:mm";
                  useCustomFont = false;
                  id = "Clock";
                }
              ];
            };
          };

          # Dock configuration (disabled)
          dock = {
            enabled = false;
          };

          # General settings
          general = {
            avatarImage = "/home/lkshrsch/.face";
            animationDisabled = true;
            dimmerOpacity = 0;
            enableShadows = false;
            showChangelogOnStartup = false;
            radiusRatio = 0.75;
          };

          # Idle configuration (replaces hypridle)
          idle = {
            enabled = true;
            lockTimeout = 600; # Lock after 10 minutes
            screenOffTimeout = 1800; # Turn off monitors after 30 minutes
            suspendTimeout = 0; # Suspend disabled (0 = disabled)
          };

          # Notifications configuration
          notifications = {
            enableMarkdown = true;
            enableMediaToast = true;
            respectExpireTimeout = true;
            backgroundOpacity = lib.mkForce 0.75;
          };

          # UI configuration
          ui = {
            settingsPanelSideBarCardStyle = true;
            panelBackgroundOpacity = lib.mkForce 0.0;
          };
        };

        # Plugin sources and configuration
        plugins = {
          sources = [
            {
              enabled = true;
              name = "Official Noctalia Plugins";
              url = "https://github.com/noctalia-dev/noctalia-plugins";
            }
          ];
          states = {
            privacy-indicator = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
            polkit-agent = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
            workspace-overview = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };

          };
          version = 2;
        };

        # Plugin-specific settings
        pluginSettings = {
          privacy-indicator = {
            activeColor = "primary";
            enableToast = true;
            hideInactive = false;
            iconSpacing = 4;
            inactiveColor = "none";
            micFilterRegex = "";
            removeMargins = false;
          };
          polkit-agent = { };
          workspace-overview = { };
        };
      };

      # Noctalia Shell additions to Hyprland
      wayland.windowManager.hyprland.settings = {
        # Auto-start Noctalia Shell
        exec-once = [
          "uwsm app -- noctalia-shell"
        ];
        layerrule = [
          "blur on, match:namespace noctalia-background-.*$"
          "blur_popups on, match:namespace noctalia-background-.*$"
          "ignore_alpha 0.5, match:namespace noctalia-background-.*$"
        ];
      };
    };
}
