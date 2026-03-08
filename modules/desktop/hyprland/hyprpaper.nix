_: {
  flake.homeManagerModules.desktop-hyprland-hyprpaper = _: {
    services.hyprpaper = {
      enable = true;
      settings = {
        splash = false;
      };
    };
  };
}
