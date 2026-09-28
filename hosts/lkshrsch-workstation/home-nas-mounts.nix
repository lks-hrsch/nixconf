outer: {
  configurations.nixos."lkshrsch-workstation".module =
    { pkgs, ... }:
    {
      imports = [ outer.config.flake.modules.nixos.home-nas-mounts ];

      services.gvfs.enable = true;

      homeNasMounts = {
        enable = true;
        server = "192.168.1.16";
        extraPackages = [ pkgs.samba ];
      };
    };
}
