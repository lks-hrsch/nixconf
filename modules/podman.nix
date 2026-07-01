_: {
  flake = {
    modules = {
      nixos.podman =
        {
          pkgs,
          ...
        }:
        {
          # podman
          # https://mynixos.com/nixpkgs/options/virtualisation.podman
          # https://nixos.wiki/wiki/Podman
          # Useful other development tools
          environment.systemPackages = with pkgs; [
            podman
            podman-compose
          ];

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
        };

      darwin.podman = _: {
        # https://github.com/podman-desktop/podman-desktop/issues/13922

        homebrew = {
          taps = [
            # Trust the tap (Homebrew 6.0); note it doesn't cover krunkit's transitive same-tap deps — see HOMEBREW_NO_REQUIRE_TAP_TRUST in darwin/homebrew.nix.
            {
              name = "slp/krunkit";
              trusted = true;
            }
          ];
          brews = [
            "helm"
            "docker"
            "docker-compose"
            "podman"
            "podman-compose"
            "slp/krunkit/krunkit"
          ];
          casks = [
            "podman-desktop"
          ];
        };
      };

      homeManager.podman =
        {
          pkgs,
          lib,
          ...
        }:
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
