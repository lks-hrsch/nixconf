{
  config,
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      imports = [
        config.flake.modules.nixos.boot
        config.flake.modules.nixos.internationalisation
        config.flake.modules.nixos.nixvim
        config.flake.modules.nixos.sops
        config.flake.modules.nixos.ssh
        config.flake.modules.nixos.time
        config.flake.modules.nixos.users
        config.flake.modules.nixos.zsh

        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        inputs.quadlet-nix.nixosModules.quadlet
      ];

      nixpkgs = {
        hostPlatform = lib.mkDefault "x86_64-linux";
        config.allowUnfree = lib.mkDefault true;
        overlays = [
          config.repo.overlays.unstable
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
          substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "https://numtide.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
        };
      };

      programs.nix-ld.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;
    };
}
