_: {
  flake.modules.homeManager.bruno =
    { pkgs, ... }:
    {
      home.packages = with pkgs.unstable; [
        bruno
        bruno-cli
      ];
    };
}
