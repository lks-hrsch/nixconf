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
            podman-compose # start group of containers for dev

            docker
            docker-compose # start group of containers for dev
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
            "slp/krunkit"
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
          home.packages =
            with pkgs;
            [
              kubectl
              minikube

              argocd
              kubeseal
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              podman-desktop
            ];

          programs.k9s.enable = true;
        };
    };
  };
}
