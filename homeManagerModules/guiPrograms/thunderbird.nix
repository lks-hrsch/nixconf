{ ... }:
{
  accounts = import ../../secrets/accounts.nix { };

  programs.thunderbird = {
    enable = true;
    profiles.lkshrsch = {
      isDefault = true;
      withExternalGnupg = true;
    };
    settings = {
      "privacy.donottrackheader.enabled" = true;
      "mailnews.start_page.enabled" = false;
    };
  };
}
