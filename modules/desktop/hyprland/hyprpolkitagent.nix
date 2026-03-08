_: {
  flake.homeManagerModules.desktop-hyprland-hyprpolkitagent = _: {
    services.hyprpolkitagent = {
      enable = true;
    };
  };
}
