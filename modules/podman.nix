{ ... }:
{
  flake.nixosModules.podman =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        podman
        podman-desktop
        podman-compose
        krunkit

        docker
        docker-compose
      ];
    };
  flake.darwinModules.podman =
    { ... }:
    {
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
  flake.homeManagerModules.podman =
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
}
