_: {
  flake.modules.homeManager.azure =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        azure-cli
      ];
    };
}
