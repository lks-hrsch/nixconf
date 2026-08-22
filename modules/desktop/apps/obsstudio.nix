_: {
  flake.modules.homeManager.obsstudio = { pkgs, lib, ... }: lib.mkIf pkgs.stdenv.isLinux {
    programs.obs-studio.enable = true;
  };
}
