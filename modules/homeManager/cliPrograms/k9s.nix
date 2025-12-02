{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    argocd
    kubeseal
    minikube
  ];

  programs.k9s.enable = true;
}
