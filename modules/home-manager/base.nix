{ config, ... }:
{
  flake.modules.homeManager.work =
    { ... }:
    {
      imports = with config.flake.modules.homeManager; [
        jetbrains
      ];
    };

  flake.modules.homeManager.base =
    { ... }:
    {
      imports = with config.flake.modules.homeManager; [
        claude-code
        git
        gpg
        latex
        lazygit
        mcp
        opencode
        podman
        skills
        sops
        ssh
        stylix
        tmux
        uv
        zsh
      ];

      programs.home-manager.enable = true;
    };
}
