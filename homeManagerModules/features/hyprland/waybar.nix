{ ... }:
let
  interval = 5;

  workspaces = {
    format = "{icon}";
    on-click = "activate";
    all-outputs = true;
    format-icons = {
      "1" = "一";
      "2" = "二";
      "3" = "三";
      "4" = "四";
      "5" = "五";
      "6" = "六";
      "7" = "七";
      "8" = "八";
      "9" = "九";
    };
    persistent-workspaces = {
      "1" = [ ];
      "2" = [ ];
      "3" = [ ];
      "4" = [ ];
      "5" = [ ];
      "6" = [ ];
      "7" = [ ];
      "8" = [ ];
      "9" = [ ];
    };
  };

  custom_nixos_menu = {
    format = "";
    on-click = "rofi -show drun";
    on-click-right = "~/.config/rofi/power-menu/power-menu.sh";
  };

  clock = {
    format = "{:%A, %d %B %Y | %R}";
  };

  mainWaybarConfig = {
    layer = "top"; # Waybar at top layer
    position = "top"; # Waybar position (top|bottom|left|right)
    margin = "4";
    # Choose the order of the modules
    output = "DP-3";
    reload_style_on_change = true;
    modules-left = [
      "custom/nixos-menu"
      "hyprland/workspaces"
      "wlr/taskbar"
    ];
    modules-right = [
      "tray"
      "idle_inhibitor"
      "pulseaudio"
      "cpu"
      "temperature"
      "custom/gpu-utilization"
      "custom/gpu-temperature"
      "memory"
      # "hyprland/language",
      "network"
      "clock"
    ];

    "custom/nixos-menu" = custom_nixos_menu;
    "wlr/workspaces" = workspaces;
    "hyprland/workspaces" = workspaces;
    "clock" = clock;

    tray = {
      spacing = 5;
    };
    idle_inhibitor = {
      on-click-right = "hyprlock";
      format = "{icon} ";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };
    pulseaudio = {
      format = "{volume}% s";
      on-click-right = "pavucontrol";
    };
    cpu = {
      interval = interval;
      format = "{usage}% ({load}) ";
      states = {
        warning = 70;
        critical = 90;
      };
    };
    temperature = {
      interval = interval;
      hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
      format = "{temperatureC}°C  ";
    };
    "custom/gpu-utilization" = {
      exec = "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits";
      format = "{}% ";
      interval = interval;
    };
    "custom/gpu-temperature" = {
      exec = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
      format = "{}°C  ";
      interval = interval;
    };
    memory = {
      interval = interval;
      format = "{used:0.1f}G/{total:0.1f}G ";
      states = {
        warning = 70;
        critical = 90;
      };
    };
    network = {
      interval = interval;
      format-wifi = " {essid}({signalStrength}%) {bandwidthDownBytes} /{bandwidthUpBytes}";
      format-ethernet = " {bandwidthDownBytes} /{bandwidthUpBytes}";
      format-disconnected = "Disconnected";
      tooltip-format = "{ifname}: {ipaddr}/{cidr}";
    };
  };

  auxilliaryWaybarConfig = {
    layer = "top"; # Waybar at top layer
    position = "top"; # Waybar position (top|bottom|left|right)
    margin = "4";
    # Choose the order of the modules
    output = "!DP-3";
    reload_style_on_change = true;
    modules-left = [
      "custom/nixos-menu"
      "hyprland/workspaces"
      "wlr/taskbar"
    ];
    modules-right = [
      "clock"
    ];

    "custom/nixos-menu" = custom_nixos_menu;
    "wlr/workspaces" = workspaces;
    "hyprland/workspaces" = workspaces;
    "clock" = clock;
  };

  css = ''
    * {
        background-color: transparent;
        color: rgba(205, 214, 244, 1);
        border-radius: 10px;
    }

    tooltip,
    menu {
        background-color: rgba(24, 24, 37, 1);
    }

    #custom-nixos-menu {
        font-size: 18px;
        background-color: rgba(24, 24, 37, 1);
        padding-left: 10px;
        padding-right: 17px;
        margin-left: 1px;
        margin-right: 1px;
    }

    #workspaces,
    #taskbar,
    #window,
    #tray,
    #idle_inhibitor,
    #pulseaudio,
    #network,
    #cpu,
    #temperature,
    #custom-gpu-utilization,
    #custom-gpu-temperature,
    #memory,
    #language,
    #clock {
        background-color: rgba(24, 24, 37, 1);
        padding-left: 10px;
        padding-right: 10px;
        margin-left: 1px;
        margin-right: 1px;
    }

    #workspaces button.active {
        background-color: rgba(49, 50, 68, 1);
        font-weight: bolder;
    }
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
    style = css;
    settings = {
      mainBar = mainWaybarConfig;
      auxilliaryBar = auxilliaryWaybarConfig;
    };
  };
}
