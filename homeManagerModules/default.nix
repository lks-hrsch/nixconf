{ ... }:
{

  imports = [
    ./features/hyprland
    ./features/stylix.nix
    ./features/xdg.nix

    ./cliPrograms/btop.nix
    ./cliPrograms/git.nix
    ./cliPrograms/gpg.nix
    ./cliPrograms/ssh.nix
    ./cliPrograms/starship.nix
    ./cliPrograms/tmux.nix
    ./cliPrograms/zsh.nix

    ./files/uwsm-env.nix

    ./guiPrograms/alacritty.nix
    ./guiPrograms/firefox.nix
    ./guiPrograms/obsidian.nix
    ./guiPrograms/obsstudio.nix
    ./guiPrograms/thunderbird.nix
    ./guiPrograms/vscode.nix
  ];

}
