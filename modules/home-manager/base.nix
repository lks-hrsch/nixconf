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
        codex
        git
        gpg
        latex
        mcp
        opencode
        podman
        skills
        sops
        ssh
        stylix
        zsh
      ];

      programs.home-manager.enable = true;
    };
}
