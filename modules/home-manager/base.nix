{ self, ... }:
{
  flake.modules.homeManager.work =
    { ... }:
    {
      imports = [
        self.outputs.modules.homeManager.jetbrains
        self.outputs.modules.homeManager.azure
      ];
    };

  flake.modules.homeManager.base =
    { ... }:
    {
      imports = [
        self.outputs.modules.homeManager.alacritty
        self.outputs.modules.homeManager.antigravity
        self.outputs.modules.homeManager.firefox
        self.outputs.modules.homeManager.git
        self.outputs.modules.homeManager.gpg
        self.outputs.modules.homeManager.latex
        self.outputs.modules.homeManager.manual
        self.outputs.modules.homeManager.mcp
        self.outputs.modules.homeManager.obsidian
        self.outputs.modules.homeManager.podman
        self.outputs.modules.homeManager.zsh
        self.outputs.modules.homeManager.sops
        self.outputs.modules.homeManager.ssh
        self.outputs.modules.homeManager.stylix
        self.outputs.modules.homeManager.vscode
      ];

      programs.home-manager.enable = true;
    };
}
