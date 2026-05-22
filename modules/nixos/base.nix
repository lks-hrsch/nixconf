{
  config,
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_18;

      imports = [
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
        hostPlatform = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [
          config.repo.overlays.unstable
          config.repo.overlays.firefox-addons
          config.repo.overlays.nix-vscode-extensions
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
            "https://hyprland.cachix.org"
            "https://noctalia.cachix.org"
            "https://cache.nixos-cuda.org"
            "https://cuda-maintainers.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          ];
        };
      };

      programs.nix-ld.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;
    };
}
