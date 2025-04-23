{ lib, pkgs, ... }: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      gpg = {
        format = "ssh";
      };
      "gpg \"ssh\"" = {
        program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      };
      commit = {
        gpgsign = true;
      };

      user = import ../../secrets/git-user.nix;
    };
  };
}
