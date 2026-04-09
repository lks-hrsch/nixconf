{ inputs, ... }:
{
  flake.modules.homeManager.desktop-hyprland-noctalia-shell =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Install supporting packages
      home.packages = with pkgs; [
        quickshell # Required for 'qs' command for IPC
        netbird # Required for netbird plugin
        dmenu # Fallback menu (needed for cliphist)
      ];

      # Configure Noctalia Shell with full settings from v4.7.5
      programs.noctalia-shell = {
        enable = true;

        settings = {
          # AppLauncher configuration
          appLauncher = {
            autoPasteClipboard = false;
            clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
            clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
            clipboardWrapText = true;
            customLaunchPrefix = "";
            customLaunchPrefixEnabled = false;
            density = "default";
            enableClipPreview = true;
            enableClipboardChips = true;
            enableClipboardHistory = true;
            enableClipboardSmartIcons = true;
            enableSessionSearch = true;
            enableSettingsSearch = true;
            enableWindowsSearch = true;
            iconMode = "tabler";
            ignoreMouseInput = false;
            overviewLayer = false;
            pinnedApps = [ ];
            position = "center";
            screenshotAnnotationTool = "";
            showCategories = true;
            showIconBackground = false;
            sortByMostUsed = true;
            terminalCommand = "uwsm app -- alacritty -e";
            viewMode = "list";
          };

          # Audio configuration
          audio = {
            mprisBlacklist = [ ];
            preferredPlayer = "";
            spectrumFrameRate = 30;
            spectrumMirrored = true;
            visualizerType = "none";
            volumeFeedback = false;
            volumeFeedbackSoundFile = "";
            volumeOverdrive = false;
            volumeStep = 5;
          };

          # Brightness configuration
          brightness = {
            backlightDeviceMappings = [ ];
            brightnessStep = 5;
            enableDdcSupport = false;
            enforceMinimum = true;
          };

          # Calendar configuration
          calendar = {
            cards = [
              {
                enabled = true;
                id = "calendar-header-card";
              }
              {
                enabled = true;
                id = "calendar-month-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
            ];
          };

          # Color schemes (Stylix will override predefinedScheme with Catppuccin)
          colorSchemes = {
            darkMode = true;
            generationMethod = "tonal-spot";
            manualSunrise = "06:30";
            manualSunset = "18:30";
            monitorForColors = "";
            predefinedScheme = "Noctalia (default)";
            schedulingMode = "off";
            syncGsettings = true;
            useWallpaperColors = false;
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
                enabled = true;
                id = "weather-card";
              }
              {
                enabled = true;
                id = "media-sysmon-card";
              }
            ];
            diskPath = "/";
            position = "close_to_bar_button";
            shortcuts = {
              left = [ ];
              right = [ { id = "NightLight"; } ];
            };
          };

          # Desktop widgets (disabled by default)
          desktopWidgets = {
            enabled = false;
          };

          # Hooks configuration
          hooks = {
            enabled = false;
          };

          # Idle configuration
          idle = {
            enabled = true;
            customCommands = "[]";
            fadeDuration = 5;
            lockCommand = "";
            lockTimeout = 660;
            resumeLockCommand = "";
            resumeScreenOffCommand = "";
            resumeSuspendCommand = "";
            screenOffCommand = "";
            screenOffTimeout = 600;
            suspendCommand = "";
            suspendTimeout = 1800;
          };

          # Location configuration (Dresden, Germany)
          location = {
            analogClockInCalendar = false;
            autoLocate = false;
            firstDayOfWeek = -1;
            hideWeatherCityName = false;
            hideWeatherTimezone = false;
            name = "Dresden, Germany";
            showCalendarEvents = true;
            showCalendarWeather = true;
            showWeekNumberInCalendar = false;
            use12hourFormat = false;
            useFahrenheit = false;
            weatherEnabled = true;
            weatherShowEffects = true;
            weatherTaliaMascotAlways = false;
          };

          # Network configuration
          network = {
            bluetoothAutoConnect = true;
            bluetoothDetailsViewMode = "grid";
            bluetoothHideUnnamedDevices = false;
            bluetoothRssiPollIntervalMs = 60000;
            bluetoothRssiPollingEnabled = false;
            disableDiscoverability = false;
            networkPanelView = "wifi";
            wifiDetailsViewMode = "grid";
          };

          # Night Light configuration
          nightLight = {
            enabled = true;
            autoSchedule = true;
            dayTemp = "6500";
            forced = false;
            manualSunrise = "06:30";
            manualSunset = "18:30";
            nightTemp = "4000";
          };

          # Noctalia performance settings
          noctaliaPerformance = {
            disableDesktopWidgets = true;
            disableWallpaper = true;
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
            batteryCriticalThreshold = 5;
            batteryWarningThreshold = 20;
            cpuCriticalThreshold = 90;
            cpuWarningThreshold = 80;
            criticalColor = "#f38ba8";
            diskAvailCriticalThreshold = 10;
            diskAvailWarningThreshold = 20;
            diskCriticalThreshold = 90;
            diskWarningThreshold = 80;
            enableDgpuMonitoring = true;
            externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
            gpuCriticalThreshold = 90;
            gpuWarningThreshold = 80;
            memCriticalThreshold = 90;
            memWarningThreshold = 80;
            swapCriticalThreshold = 90;
            swapWarningThreshold = 80;
            tempCriticalThreshold = 90;
            tempWarningThreshold = 80;
            useCustomColors = false;
            warningColor = "#585b70";
          };

          # Templates
          templates = {
            activeTemplates = [ ];
            enableUserTheming = false;
          };

          # Wallpaper configuration
          wallpaper = {
            automationEnabled = false;
            directory = "/home/lkshrsch/Pictures/Wallpapers";
            enableMultiMonitorDirectories = false;
            enabled = false;
            favorites = [ ];
            fillColor = "#000000";
            fillMode = "crop";
            hideWallpaperFilenames = false;
            linkLightAndDarkWallpapers = true;
            monitorDirectories = [ ];
            overviewBlur = 0.4;
            overviewEnabled = false;
            overviewTint = 0.6;
            panelPosition = "follow_bar";
            randomIntervalSec = 300;
            setWallpaperOnAllMonitors = true;
            showHiddenFiles = false;
            skipStartupTransition = false;
            solidColor = "#1a1a2e";
            sortOrder = "name";
            transitionDuration = 1500;
            transitionEdgeSmoothness = 0.05;
            transitionType = [
              "fade"
              "disc"
              "stripes"
              "wipe"
              "pixelate"
              "honeycomb"
            ];
            useOriginalImages = false;
            useSolidColor = false;
            useWallhaven = false;
            viewMode = "single";
            wallhavenApiKey = "";
            wallhavenCategories = "111";
            wallhavenOrder = "desc";
            wallhavenPurity = "100";
            wallhavenQuery = "";
            wallhavenRatios = "";
            wallhavenResolutionHeight = "";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "";
            wallhavenSorting = "relevance";
            wallpaperChangeMode = "random";
          };

          # Bar configuration
          bar = {
            autoHideDelay = 500;
            autoShowDelay = 150;
            barType = "floating";
            capsuleColorKey = "none";
            contentPadding = 2;
            density = "default";
            displayMode = "always_visible";
            enableExclusionZoneInset = true;
            fontScale = 1;
            frameRadius = 12;
            frameThickness = 8;
            hideOnOverview = false;
            marginHorizontal = 4;
            marginVertical = 4;
            middleClickAction = "none";
            middleClickCommand = "";
            middleClickFollowMouse = false;
            monitors = [ ];
            mouseWheelAction = "none";
            mouseWheelWrap = true;
            outerCorners = true;
            reverseScroll = false;
            rightClickAction = "controlCenter";
            rightClickCommand = "";
            rightClickFollowMouse = true;
            screenOverrides = [ ];
            showCapsule = true;
            showOnWorkspaceSwitch = true;
            showOutline = false;
            useSeparateOpacity = false;
            widgetSpacing = 6;
            widgets = {
              left = [
                {
                  colorizeDistroLogo = false;
                  colorizeSystemIcon = "none";
                  customIconPath = "";
                  enableColorization = false;
                  icon = "noctalia";
                  useDistroLogo = false;
                  id = "AppLauncher";
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
                  ];
                  id = "Tray";
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
                  displayMode = "onhover";
                  iconColor = "none";
                  textColor = "none";
                  id = "Network";
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
            animationSpeed = 1;
            colorizeIcons = false;
            deadOpacity = 0.6;
            displayMode = "auto_hide";
            dockType = "floating";
            enabled = false;
            floatingRatio = 1;
            groupApps = false;
            groupClickAction = "cycle";
            groupContextMenuMode = "extended";
            groupIndicatorStyle = "dots";
            inactiveIndicators = false;
            indicatorColor = "primary";
            indicatorOpacity = 0.6;
            indicatorThickness = 3;
            launcherIcon = "";
            launcherIconColor = "none";
            launcherPosition = "end";
            launcherUseDistroLogo = false;
            monitors = [ ];
            onlySameOutput = true;
            pinnedApps = [ ];
            pinnedStatic = false;
            position = "bottom";
            showDockIndicator = false;
            showLauncherIcon = false;
            sitOnFrame = false;
            size = 1;
          };

          # General settings
          general = {
            allowPanelsOnScreenWithoutBar = true;
            allowPasswordWithFprintd = false;
            animationDisabled = true;
            animationSpeed = 1;
            autoStartAuth = false;
            avatarImage = "/home/lkshrsch/.face";
            boxRadiusRatio = 1;
            clockFormat = "hh\\nmm";
            clockStyle = "custom";
            compactLockScreen = false;
            dimmerOpacity = 0;
            enableBlurBehind = true;
            enableLockScreenCountdown = true;
            enableLockScreenMediaControls = false;
            enableShadows = false;
            forceBlackScreenCorners = false;
            iRadiusRatio = 0.99;
            keybinds = {
              keyDown = [ "Down" ];
              keyEnter = [
                "Return"
                "Enter"
              ];
              keyEscape = [ "Esc" ];
              keyLeft = [ "Left" ];
              keyRemove = [ "Del" ];
              keyRight = [ "Right" ];
              keyUp = [ "Up" ];
            };
            language = "";
            lockOnSuspend = true;
            lockScreenAnimations = false;
            lockScreenBlur = 0;
            lockScreenCountdownDuration = 10000;
            lockScreenMonitors = [ ];
            lockScreenTint = 0;
            passwordChars = false;
            reverseScroll = false;
            scaleRatio = 1;
            screenRadiusRatio = 1;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            showChangelogOnStartup = true;
            showHibernateOnLockScreen = false;
            showScreenCorners = false;
            showSessionButtonsOnLockScreen = true;
            smoothScrollEnabled = true;
            telemetryEnabled = false;
            radiusRatio = 1;
          };

          # Notifications configuration
          notifications = {
            clearDismissed = true;
            criticalUrgencyDuration = 15;
            density = "default";
            enableBatteryToast = true;
            enableKeyboardLayoutToast = true;
            enableMarkdown = true;
            enableMediaToast = true;
            location = "top_right";
            lowUrgencyDuration = 3;
            monitors = [ ];
            normalUrgencyDuration = 8;
            overlayLayer = true;
            respectExpireTimeout = true;
            saveToHistory = {
              critical = true;
              low = true;
              normal = true;
            };
            sounds = {
              criticalSoundFile = "";
              enabled = false;
              excludedApps = "discord,firefox,chrome,chromium,edge";
              lowSoundFile = "";
              normalSoundFile = "";
              separateSounds = false;
              volume = 0.5;
            };
            backgroundOpacity = lib.mkForce 0.75;
          };

          # OSD (On-Screen Display) configuration
          osd = {
            autoHideMs = 2000;
            enabled = true;
            enabledTypes = [
              0
              1
              2
            ];
            location = "top_right";
            monitors = [ ];
            overlayLayer = true;
          };

          # Plugins configuration
          plugins = {
            autoUpdate = true;
            notifyUpdates = true;
          };

          # UI configuration
          ui = {
            boxBorderEnabled = false;
            fontDefaultScale = 1;
            fontFixedScale = 1;
            panelsAttachedToBar = true;
            scrollbarAlwaysVisible = true;
            settingsPanelMode = "attached";
            settingsPanelSideBarCardStyle = true;
            tooltipsEnabled = true;
            translucentWidgets = false;
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
            netbird = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
          };
          version = 2;
        };

        # Plugin-specific settings
        pluginSettings = {
          "privacy-indicator" = { };
          "polkit-agent" = { };
          netbird = {
            compactMode = false;
            showIpAddress = true;
            showPeerCount = true;
            refreshInterval = 5000;
          };
        };
      };

      # Auto-start Noctalia Shell via Hyprland
      wayland.windowManager.hyprland.settings.exec-once = [
        "uwsm app -- noctalia-shell"
      ];
    };
}
