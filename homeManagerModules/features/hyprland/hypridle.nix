{ ... }: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # start exactly one hyprlock instance
        lock_cmd = "pidof hyprlock || hyprlock";
        # also lock when the machine is about to suspend
        before_sleep_cmd = "loginctl lock-session";
        # bring the screens back after resume
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # lock screen
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || hyprlock";
        }

        # turn of monitor
        {
          timeout = 1800;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on"; # wake screens on activity
        }
      ];
    };
  };
}
