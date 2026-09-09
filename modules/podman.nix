{ config, ... }:
let
  inherit (config.flake.users.owner) username;
in
{
  flake = {
    modules = {
      nixos.podman =
        { pkgs, ... }:
        {
          # https://mynixos.com/nixpkgs/options/virtualisation.podman
          # https://nixos.wiki/wiki/Podman
          # virtualisation.podman.enable already installs the podman package itself.
          environment.systemPackages = [ pkgs.podman-compose ];

          virtualisation = {
            containers = {
              enable = true;
            };
            podman = {
              enable = true;
              autoPrune.enable = true;
              defaultNetwork.settings = {
                dns_enabled = true;
              };
              dockerCompat = true; # Enable Docker compatibility mode
              dockerSocket.enable = true; # Enable Docker socket for compatibility
            };
            quadlet = {
              enable = true;
              autoUpdate.enable = true;
            };
          };

          # dockerSocket.enable creates this group; membership is required to connect.
          users.users.${username}.extraGroups = [ "podman" ];
        };

      darwin.podman = _: {
        # https://github.com/podman-desktop/podman-desktop/issues/13922

        homebrew = {
          taps = [
            # Trust the tap (Homebrew 6.0); note it doesn't cover krunkit's transitive same-tap deps — see HOMEBREW_NO_REQUIRE_TAP_TRUST in darwin/homebrew.nix.
            {
              name = "libkrun/krun";
              trusted = true;
            }
          ];
          brews = [
            "helm"
            "docker"
            "docker-compose"
            "podman"
            "podman-compose"
            "libkrun/krun/krunkit"
          ];
          casks = [
            "podman-desktop"
          ];
        };
      };

      homeManager.podman =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            kubectl
            minikube

            argocd
            kubeseal
          ];

          programs.k9s.enable = true;
        };
    };
  };
}
