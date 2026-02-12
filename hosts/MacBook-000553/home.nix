{
  lib,
  inputs,
  ...
}:
{
  # Import the default home-manager modules
  # Linux-specific modules will be automatically excluded on Darwin
  imports = [
    inputs.self.outputs.modules.homeManager.default
    inputs.self.homeManagerModules.git
    inputs.self.homeManagerModules.ssh
    inputs.self.homeManagerModules.shell
    inputs.self.homeManagerModules.stylix
    inputs.self.homeManagerModules.sops
    inputs.self.homeManagerModules.vscode
  ];

  home = {
    stateVersion = "25.05";
    homeDirectory = lib.mkForce "/Users/lkshrsch";
    username = "lkshrsch";
  };
}
