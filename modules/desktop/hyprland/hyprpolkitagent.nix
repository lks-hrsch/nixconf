_: {
  flake.modules.homeManager.desktop-hyprland-hyprpolkitagent = _: {
    services.hyprpolkitagent = {
      enable = true;
    };
  };
}
