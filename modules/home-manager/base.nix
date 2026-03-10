{ self, ... }:
{
  flake.modules.homeManager.work =
    { ... }:
    {
      imports = with self.outputs.modules.homeManager; [
        jetbrains
        azure
      ];
    };

  flake.modules.homeManager.base =
    { ... }:
    {
      imports = with self.outputs.modules.homeManager; [
        alacritty
        antigravity
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
