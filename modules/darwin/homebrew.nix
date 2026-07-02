_: {
  flake.modules.darwin.homebrew = _: {
    # issues in newer macOS versions with mas package use brew version
    # https://github.com/mas-cli/mas/issues/1029
    # environment.systemPackages = with pkgs; [
    #   mas # https://github.com/mas-cli/mas
    # ];

    # Homebrew configuration
    homebrew = {
      enable = true;

      # Auto-update Homebrew and packages
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
        # Homebrew 5.1.15+ requires --force when --cleanup is used
        extraFlags = [ "--force" ];
        # Homebrew 6.0 tap-trust doesn't cover transitively-loaded deps from 3rd-party taps (krunkit -> virglrenderer); disable the check. Deprecated escape hatch — revisit when removed.
        extraEnv.HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
      };

      taps = [
        "tw93/tap" # for mole
        "steipete/tap"
      ];

      # CLI tools (formulae)
      brews = [
        "helm"
        "mas" # https://github.com/mas-cli/mas
        "steipete/tap/remindctl"
        "tw93/tap/mole" # https://github.com/tw93/Mole
      ];

      # GUI applications (casks)
      casks = [
        "aldente"
        "claude"
        # Signed app in /Applications required for 1Password desktop-app
        # integration; profile is managed by home-manager (firefox.nix).
        "firefox"
        "open-webui"
        "postman"
        "rustdesk"
        "spotify"
        "syncthing-app"
        "vlc"
        "winbox"
      ];

      # https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.masApps
      masApps = {
        "1Password for Safari" = 1569813296; # Safari extension

        # University
        "eduVPN" = 1317704208;
        "Goodnotes" = 1444383602;

        # Business and productivity
        "Bitwarden" = 1352778147;
        "Microsoft Excel" = 462058435;
        "Microsoft Outlook" = 985367838;
        "Microsoft PowerPoint" = 462062816;
        "Microsoft Word" = 462054704;
        "OneDrive" = 823766827;

        # Random useful apps
        "AusweisApp" = 948660805;
      };
    };
  };
}
