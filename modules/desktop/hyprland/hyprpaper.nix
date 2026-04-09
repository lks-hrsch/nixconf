_: {
  flake.modules.homeManager.desktop-hyprland-hyprpaper = _: {
    services.hyprpaper = {
      enable = true;
      settings = {
        splash = false;
      };
    };
  };
}
