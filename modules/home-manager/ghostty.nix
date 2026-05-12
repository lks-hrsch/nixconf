_: {
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        settings = {
          shell-integration-features = "ssh-env";
        };
        package = if pkgs.stdenv.isDarwin then pkgs.unstable.ghostty-bin else pkgs.unstable.ghostty;
      };
    };
}
