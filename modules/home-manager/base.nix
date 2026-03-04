{ self, config, ... }:
{
  # Kept as alias so workstation-nixos/home.nix can still import it
  flake.homeManagerModules.default = config.flake.modules.homeManager.base;

  flake.modules.homeManager.base =
    { ... }:
    {
      imports = [
        self.homeManagerModules.alacritty
        self.homeManagerModules.antigravity
        self.homeManagerModules.firefox
        self.homeManagerModules.git
        self.homeManagerModules.gpg
        self.homeManagerModules.jetbrains
        self.homeManagerModules.latex
        self.homeManagerModules.manual
        self.homeManagerModules.mcp
        self.homeManagerModules.obsidian
        self.homeManagerModules.podman
        self.homeManagerModules.shell
        self.homeManagerModules.sops
        self.homeManagerModules.ssh
        self.homeManagerModules.stylix
        self.homeManagerModules.vscode
      ];

      programs.home-manager.enable = true;
    };
}
