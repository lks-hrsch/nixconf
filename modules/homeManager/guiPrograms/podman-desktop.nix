{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # podman-desktop # https://github.com/podman-desktop/podman-desktop/issues/13922

    docker-compose
    podman-compose

    kubectl
    minikube
  ];
}
