{
  config,
  self,
  inputs,
  ...
}:
let
  top = config;
in
{
  flake.modules.nixos.base =
    { config, lib, ... }:
    {
      imports = [
        top.flake.modules.nixos.alloy
        top.flake.modules.nixos.boot
        top.flake.modules.nixos.internationalisation
        top.flake.modules.nixos.lazygit
        top.flake.modules.nixos.nixvim
        top.flake.modules.nixos.sops
        top.flake.modules.nixos.ssh
        top.flake.modules.nixos.time
        top.flake.modules.nixos.users
        top.flake.modules.nixos.zsh

        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        inputs.quadlet-nix.nixosModules.quadlet
      ];

      # Set directly, never networking.domain: that would also add a resolv.conf search domain.
      networking.fqdn = lib.mkDefault "${config.networking.hostName}.lukashirsch.de";

      nixpkgs = {
        hostPlatform = lib.mkDefault "x86_64-linux";
        config.allowUnfree = lib.mkDefault true;
        overlays = [
          top.repo.overlays.unstable
        ];
      };

      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 21d";
        };
        optimise.automatic = true;
        settings = {
          # nix.extraOptions is appended after nix.settings and would silently
          # clobber experimental-features set here by another module.
          experimental-features = [
            "nix-command"
            "flakes"
          ];
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
