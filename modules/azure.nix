_: {
  flake.homeManagerModules.azure =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        azure-cli
      ];
    };
}
