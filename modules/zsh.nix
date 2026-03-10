_: {
  flake = {
    modules = {
      nixos.zsh =
        { pkgs, ... }:
        {
          environment.shells = with pkgs; [ zsh ];
          users.defaultUserShell = pkgs.zsh;
          programs = {
            zsh.enable = true;
            tmux.enable = true;
          };

          # global system packages
          environment.systemPackages = with pkgs; [
            btop
            pciutils
            usbutils
          ];
        };

      darwin.zsh =
        { pkgs, ... }:
        {
          environment.shells = with pkgs; [ zsh ];
          programs = {
            zsh.enable = true;
            tmux.enable = true;
          };

          # global system packages
          environment.systemPackages = with pkgs; [
            btop
            pciutils
            usbutils
          ];
        };

      homeManager.zsh =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            jq
            wget
            nmap
            iperf3
            smartmontools
          ];

          programs = {
            zsh = {
              enable = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;
              enableCompletion = true;
              history = {
                expireDuplicatesFirst = true;
                ignoreDups = true;
              };
            };

            starship = {
              enable = true;
              enableZshIntegration = true;
              enableBashIntegration = true;
              settings = {
                hostname.ssh_only = false;
                username.show_always = true;
              };
            };

            direnv = {
              enable = true;
              nix-direnv.enable = true;
            };

            tmux = {
              enable = true;
              clock24 = true;
            };

            fastfetch.enable = true;
            btop.enable = true;
          };
        };
    };
  };
}
