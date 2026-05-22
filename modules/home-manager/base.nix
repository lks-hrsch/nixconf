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
        claude-code
        ghostty
        firefox
        git
        gpg
        latex
        manual
        mcp
        obsidian
        podman
        skills
        zsh
        sops
        ssh
        opencode
        stylix
        vscode
      ];

      programs.home-manager.enable = true;
    };
}
