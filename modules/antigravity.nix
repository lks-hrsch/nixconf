{ ... }:
{
  flake.homeManagerModules.antigravity =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = lib.mkIf pkgs.stdenv.isLinux [
        pkgs.antigravity
      ];
    };
}
