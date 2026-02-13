{ ... }:
{
  flake = {
    nixosModules.zsh = {
      # https://wiki.nixos.org/wiki/Zsh
      programs.zsh = {
        enable = true;
      };
    };

    darwinModules.zsh = {
      # https://wiki.nixos.org/wiki/Zsh
      programs.zsh = {
        enable = true;
      };
    };
  };
}
