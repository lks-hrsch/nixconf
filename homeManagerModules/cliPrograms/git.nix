{
  lib,
  pkgs,
  config,
  ...
}:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    includes = [
      {
        path = "${config.sops.secrets."git/user-lks-hrsch".path}";
      }
    ];
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
    };
  };
}
