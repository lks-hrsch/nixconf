{ ... }:
{
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
    };

    taps = [
      "tw93/tap" # for mole
      "slp/krunkit" # for krunkit
    ];

    # CLI tools (formulae)
    brews = [
      "appium"
      "git-svn"
      "helm"
      "ios-deploy"
      "mas" # https://github.com/mas-cli/mas
      "tw93/tap/mole" # https://github.com/tw93/Mole
      "podman"
      "rbenv"
      "slp/krunkit/krunkit"
      "subversion"
    ];

    # GUI applications (casks)
    casks = [
      "aldente"
      "anki"
      "fork"
      "google-chrome"
      "keepassxc"
      "languagetool-desktop"
      "microsoft-edge"
      "openvpn-connect"
      "podman-desktop"
      "postman"
      "rustdesk"
      "spotify"
      "syncthing-app"
      "vlc"
      "winbox"
      "zoom"
    ];

    # https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.masApps
    masApps = {
      "1Password for Safari" = 1569813296; # Safari extension
      "LanguageTool" = 1534275760; # Safari extension
      "Tailscale" = 1475387142;

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
      "Windows App" = 1295203466;
      "Xcode" = 497799835;
      "Developer" = 640199958;

      # Random useful apps
      "AusweisApp" = 948660805;
      "Slack for Desktop" = 803453959;
    };
  };
}
