_: {
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;
        package = pkgs.unstable.ghostty;
      };
    };
}
