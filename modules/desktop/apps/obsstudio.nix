_: {
  flake.modules.homeManager.desktop-apps-obsstudio = _: {
    programs.obs-studio = {
      enable = true;
    };
  };
}
