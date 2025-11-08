{ ... }:
{
  # Homebrew configuration
  homebrew = {
    enable = true;

    # Auto-update Homebrew and packages
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };

    # CLI tools (formulae)
    brews = [
    ];

    # GUI applications (casks)
    casks = [
      "1password"
      "1password-cli"
      "alacritty"
      "cursor"
      "firefox"
      "fork"
      "obsidian"
      "ollama-app"
      "onyx"
      "podman-desktop"
      "spotify"
      "syncthing-app"
      "tailscale-app"
      "visual-studio-code"
      "winbox"
      "zoom"
    ];
  };
}
