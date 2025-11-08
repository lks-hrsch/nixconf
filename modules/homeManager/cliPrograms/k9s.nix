{ pkgs, ... }:
{
  home.packages = with pkgs; [
    argocd
    kubeseal
    minikube
  ];

  programs.k9s.enable = true;
}
