_: {
  flake.modules.homeManager.antigravity =
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
