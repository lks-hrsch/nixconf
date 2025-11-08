{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi.override {
      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
      ];
    };
    extraConfig = {
      modi = "window,run,drun,filebrowser,calc,emoji";
      drun-display-format = "{icon} {name}";
      show-icons = true;
      icon-theme = "Adwaita";

      display-drun = " Applications:";
      display-run = " Run";
      display-window = "Windows:";
      display-filebrowser = " Files";
      display-calc = " Calculator";
      display-emoji = "💀 Emoji";
    };
    theme = {
      "*" = {
        border = 0;
        margin = 0;
        padding = 2;
        spacing = 0;
      };
      "window" = {
        border-radius = 15;
      };
      "element" = {
        padding = "8 12";
      };
      "element selected" = {
        border-radius = 15;
      };
      "entry" = {
        padding = 12;
      };
      "inputbar" = {
        border-radius = 15;
      };
    };
  };

  home.file.rofi-power-menu = {
    enable = true;
    target = ".config/rofi/power-menu/power-menu.sh";
    executable = true;
    text = "#! /bin/sh
# Read total uptime in seconds
uptime_seconds=$(cut -d. -f1 /proc/uptime)

# Convert to days, hours, minutes
days=$(( uptime_seconds / 86400 ))
hours=$(( (uptime_seconds % 86400) / 3600 ))
minutes=$(( (uptime_seconds % 3600) / 60 ))

uptime_text=\"\"
[ $days -gt 0 ] && uptime_text=\"$uptime_text$days day(s), \"
[ $hours -gt 0 ] && uptime_text=\"$uptime_text$hours hour(s), \"
uptime_text=\"$uptime_text$minutes minute(s)\"

choice0=\" Uptime: $uptime_text\"
choice1=\"   Power Off\"
choice2=\"   Restart\"
choice3=\"   Suspend\"
choice4=\"   Hibernate\"
choice5=\"   Log Out\"
choice6=\"   Lock\"

chosen=$(printf \"$choice0\\n$choice1\\n$choice2\\n$choice3\\n$choice4\\n$choice5\\n$choice6\\n\" | rofi -dmenu -i -no-show-icons -l 7 -width 30 -p \" Goodbye \${USER}\")

case \"$chosen\" in
  \"$choice0\") ;;
  \"$choice1\") poweroff ;;
  \"$choice2\") reboot ;;
  \"$choice3\") systemctl suspend-then-hibernate ;;
  \"$choice4\") systemctl hibernate ;;
  \"$choice5\") killhypr ;;
  \"$choice6\") hyprlock ;;
esac
      ";
  };
}
