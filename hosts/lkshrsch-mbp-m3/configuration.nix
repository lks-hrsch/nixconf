{
  self,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.outputs.darwinModules.default
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # this will allow you to use nix-darwin with Determinate.
  nix.enable = false;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  system = {
    primaryUser = "lkshrsch";

    configurationRevision = self.rev or self.dirtyRev or null; # Set Git commit hash for darwin-version.
    stateVersion = 6; # $ darwin-rebuild changelog

    defaults = {
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
      };
    };
  };
}
