_: {
  flake.modules.nixos.librepods =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        librepods
      ];

    };
}
