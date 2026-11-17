_: {
  configurations.nixos."phobos".module = {
    alloy = {
      enable = true;
      hostLabel = "phobos.mars.lukashirsch.de";
      # LXC: these would report host-wide or bogus data.
      disabledCollectors = [
        "hwmon"
        "thermal_zone"
        "cpufreq"
        "diskstats"
        "zfs"
      ];
    };
  };
}
