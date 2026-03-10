_: {
  flake.modules.homeManager.desktop-hyprland-dunst = _: {
    services.dunst = {
      enable = true;
    };
  };
}
