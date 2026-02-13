{ ... }:
{
  flake.homeManagerModules.jetbrains =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        jetbrains.gateway

        jetbrains.datagrip
        jetbrains.clion
        jetbrains.rider

        # https://nixos.wiki/wiki/Android
        # android-studio
      ];
    };
}
