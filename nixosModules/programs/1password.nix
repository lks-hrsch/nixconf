{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      _1password-cli
      _1password-gui
    ];

    programs._1password = {
      enable = true;
    };
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "lkshrsch" ];
    };
  };
}
