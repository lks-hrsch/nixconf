{ ... }: {
  programs.thunderbird = {
    enable = true;
    profiles.lkshrsch = {
      isDefault = true;
      withExternalGnupg = true;
    };
    settings = {
      "privacy.donottrackheader.enabled" = true;
    };
  };
}
