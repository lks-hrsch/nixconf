{
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { ... }:
    {
      imports = [
        self.outputs.modules.nixos.features
        self.outputs.modules.nixos.internationalisation
        self.outputs.modules.nixos.nixvim
        self.outputs.modules.nixos.sops
        self.outputs.modules.nixos.ssh
        self.outputs.modules.nixos.time
        self.outputs.modules.nixos.users

        self.outputs.modules.nixos.zsh

        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        inputs.quadlet-nix.nixosModules.quadlet
      ];

      nixpkgs = {
        hostPlatform = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [
          self.outputs.custom-overlays.unstable
          self.outputs.custom-overlays.firefox-addons
          self.outputs.custom-overlays.nix-vscode-extensions
        ];
      };

      nix = {
        extraOptions = "experimental-features = nix-command flakes";
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 21d";
        };
        optimise.automatic = true;
        settings = {
          auto-optimise-store = true;
          trusted-users = [ "lkshrsch" ];
          substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "https://hyprland.cachix.org"
            "https://cuda-maintainers.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          ];
        };
      };

      programs.nix-ld.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;
    };
}
