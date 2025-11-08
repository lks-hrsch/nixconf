{ ... }:
{
  imports = [
    # Cross-platform features
    ./features/sops.nix
    ./features/stylix.nix

    # CLI programs (cross-platform)
    ./cliPrograms/btop.nix
    ./cliPrograms/git.nix
    ./cliPrograms/gpg.nix
    ./cliPrograms/ssh.nix
    ./cliPrograms/starship.nix
    ./cliPrograms/tmux.nix
    ./cliPrograms/vim.nix
    ./cliPrograms/zsh.nix

    # GUI programs (cross-platform)
    ./guiPrograms/alacritty.nix
    ./guiPrograms/firefox.nix
    ./guiPrograms/obsidian.nix
    ./guiPrograms/vscode.nix
  ];

  # Note: Linux-specific modules in ./linux should be imported
  # separately by NixOS configurations, not by Darwin configurations
}
