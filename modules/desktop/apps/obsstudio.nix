_: {
  flake.modules.homeManager.obsstudio = _: {
    programs.obs-studio = {
      enable = true;
    };
  };
}
