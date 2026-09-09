outer: {
  configurations.nixos."lkshrsch-thinkpad-e590".module = {
    imports = [ outer.config.flake.modules.nixos.home-nas-mounts ];

    # gvfs already enabled by the desktop module (Nautilus mount browsing).
    homeNasMounts = {
      enable = true;
      server = "mars.lukashirsch.de";
      cifsVersion = "3.1.1";
      mountTimeoutSec = 60;
    };
  };
}
