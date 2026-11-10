outer: {
  configurations.nixos."lkshrsch-workstation".module =
    { pkgs, ... }:
    {
      imports = [ outer.config.flake.modules.nixos.home-nas-mounts ];

      services.gvfs.enable = true;

      homeNasMountsSMB = {
        enable = true;
        server = "192.168.1.16";
        shares = [
          "backup"
          "benchmark"
          "home"
          "media"
          "photos"
          "university"
          "datasets"
        ];
        extraPackages = [ pkgs.samba ];
      };

      # NFS beside the SMB share until the OpenVAD small-file benchmark picks one.
      # The export allows only 192.168.1.40 (wired enp10s0); traffic from Wi-Fi (.83) is refused.
      homeNasMountsNFS = {
        enable = true;
        server = "192.168.1.16";
        shares = [ "datasets" ];
      };
    };
}
