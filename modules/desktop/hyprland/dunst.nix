_: {
  flake.homeManagerModules.desktop-hyprland-dunst = _: {
    services.dunst = {
      enable = true;
    };
  };
}
