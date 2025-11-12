{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    environment.systemPackages = with pkgs.unstable; [
      _1password-cli
      _1password-gui
    ];

    programs._1password = {
      enable = true;
      package = pkgs.unstable._1password-cli;
    };
    programs._1password-gui = {
      enable = true;
      package = pkgs.unstable._1password-gui;
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      polkitPolicyOwners = [ "lkshrsch" ];
    };
  };
}
