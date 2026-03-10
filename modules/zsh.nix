_: {
  flake = {
    nixosModules.zsh =
      { pkgs, ... }:
      {
        environment.shells = with pkgs; [ zsh ];
        users.defaultUserShell = pkgs.zsh;
        programs.zsh.enable = true;

        # global system packages
        environment.systemPackages = with pkgs; [
          btop
          pciutils
          usbutils
        ];
      };

    darwinModules.zsh =
      { pkgs, ... }:
      {
        environment.shells = with pkgs; [ zsh ];
        programs.zsh.enable = true;

        # global system packages
        environment.systemPackages = with pkgs; [
          btop
          pciutils
          usbutils
        ];
      };

    homeManagerModules.zsh =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          jq
          wget
          nmap
          iperf3
          smartmontools
        ];

        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          enableCompletion = true;
          history = {
            expireDuplicatesFirst = true;
            ignoreDups = true;
          };
        };

        programs.starship = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = true;
          settings = {
            hostname.ssh_only = false;
            username.show_always = true;
          };
        };

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        programs.tmux = {
          enable = true;
          clock24 = true;
        };

        programs.fastfetch.enable = true;
        programs.btop.enable = true;
      };
  };
}
