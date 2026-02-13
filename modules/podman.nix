{ ... }:
{
  flake.homeManagerModules.podman-desktop =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        # podman
        # podman-desktop # https://github.com/podman-desktop/podman-desktop/issues/13922

        docker-compose
        podman-compose

        kubectl
        minikube
      ];
      # ++ (lib.optionals pkgs.stdenv.isDarwin [
      #   krunkit # https://mynixos.com/nixpkgs/package/krunkit
      # ])

    };
}
