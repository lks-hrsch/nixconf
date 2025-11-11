{ pkgs, ... }:
{
environment.systemPackages = with pkgs; [
    mas # https://github.com/mas-cli/mas
  ];

  # Homebrew configuration
  homebrew = {
    enable = true;

    # Auto-update Homebrew and packages
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # CLI tools (formulae)
    brews = [
      "appium"
      "docker-compose"
      "git-svn"
      "helm"
      "ios-deploy"
      "podman"
      "podman-compose"
      "rbenv"
      "subversion"
    ];

    # GUI applications (casks)
    casks = [
      "1password"
      "1password-cli"
            "aldente"
      "anki"
      "discord"
            "fork"
      "google-chrome"
      "jetbrains-toolbox"
      "keepassxc"
      "languagetool-desktop"
      "microsoft-edge"
      "mullvad-vpn"
      "notion"
            "ollama-app"
      "onyx"
      "openvpn-connect"
      "podman-desktop"
      "postman"
      "rustdesk"
      "slack"
      "spotify"
      "syncthing-app"
      "tailscale-app"
      "vlc"
      "winbox"
      "windows-app"
      "zoom"
    ];

    # https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.masApps
    masApps = {
      "1Password for Safari" = 1569813296;
    };
  };
}
