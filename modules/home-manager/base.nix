{ config, ... }:
{
  flake.modules.homeManager.work =
    { ... }:
    {
      imports = with config.flake.modules.homeManager; [
        jetbrains
        azure
      ];
    };

  flake.modules.homeManager.base =
    { ... }:
    {
      imports = with config.flake.modules.homeManager; [
        alacritty
        claude-code
        firefox
        git
        gpg
        latex
        manual
        mcp
        obsidian
        podman
        zsh
        sops
        ssh
        stylix
        vscode
      ];

      programs.home-manager.enable = true;
    };
}
