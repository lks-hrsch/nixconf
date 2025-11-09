{ ... }:
{
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
      "alacritty"
      "aldente"
      "anki"
      "discord"
      "firefox"
      "fork"
      "google-chrome"
      "jetbrains-toolbox"
      "keepassxc"
      "languagetool-desktop"
      "microsoft-edge"
      "mullvad-vpn"
      "notion"
      "obsidian"
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
  };
}
