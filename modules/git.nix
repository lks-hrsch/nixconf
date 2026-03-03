_: {
  flake.homeManagerModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        git-crypt
      ];

      programs.git = {
        enable = true;
        lfs.enable = true;
        includes = [
          {
            path = "${config.sops.secrets."git/user-lks-hrsch".path}";
          }
        ];
        settings = {
          gpg = {
            format = "ssh";
          };
          "gpg \"ssh\"" = {
            program =
              if pkgs.stdenv.isDarwin then
                "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
              else
                lib.getExe' pkgs.unstable._1password-gui "op-ssh-sign";
          };
          commit = {
            gpgsign = true;
          };
        };
      };
    };
}
