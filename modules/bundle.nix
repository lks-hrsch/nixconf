{ self, ... }:
{
  flake.homeManagerModules.default = {
    imports = [
      self.homeManagerModules.alacritty
      self.homeManagerModules.antigravity
      self.homeManagerModules.firefox
      self.homeManagerModules.git
      self.homeManagerModules.jetbrains
      self.homeManagerModules.obsidian
      self.homeManagerModules.podman
      self.homeManagerModules.shell
      self.homeManagerModules.sops
      self.homeManagerModules.ssh
      self.homeManagerModules.stylix
      self.homeManagerModules.vscode
    ];
  };
}
