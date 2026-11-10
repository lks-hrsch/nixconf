outer: {
  configurations.nixos."lkshrsch-thinkpad-e590".module = {
    imports = [ outer.config.flake.modules.nixos.home-nas-mounts ];

    # gvfs already enabled by the desktop module (Nautilus mount browsing).
    homeNasMountsSMB = {
      enable = true;
      server = "mars.lukashirsch.de";
      shares = [
        "backup"
        "benchmark"
        "home"
        "media"
        "photos"
        "university"
        "datasets"
      ];
      cifsVersion = "3.1.1";
      mountTimeoutSec = 60;
    };
  };
}
