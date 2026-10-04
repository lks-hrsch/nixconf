_: {
  configurations.nixos."deimos".module = {
    alloy = {
      enable = true;
      hostLabel = "deimos.mars.lukashirsch.de";
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
