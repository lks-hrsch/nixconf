{
  self,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.outputs.modules.darwin.default
    inputs.self.outputs.modules.shared.default
  ];

  features = {
    desktop.enable = true;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
  };

  networking = {
    hostName = "MacBook-000553";
  };

  # this will allow you to use nix-darwin with Determinate.
  nix.enable = false;

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
