{ config, ... }:
{
  flake.modules.homeManager.desktop-apps-thunderbird =
    { pkgs, ... }:
    {
      accounts = import ../../../secrets/accounts.nix { };

      programs.thunderbird = {
        enable = true;
        package = pkgs.thunderbird-bin;

        profiles.${config.flake.users.owner.username} = {
          isDefault = true;
          withExternalGnupg = true;
        };

        settings = {
          "privacy.donottrackheader.enabled" = true;
          "mailnews.start_page.enabled" = false;
        };
      };
    };
}
