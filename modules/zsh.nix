_: {
  flake = {
    modules =
      let
        baseZshConfig =
          { pkgs, ... }:
          let
            ghosttyTerminfo =
              if pkgs.stdenv.isDarwin then pkgs.unstable.ghostty-bin.terminfo else pkgs.unstable.ghostty.terminfo;
          in
          {
            environment.shells = with pkgs; [ zsh ];
            programs = {
              zsh.enable = true;
              tmux.enable = true;
            };

            # global system packages
            environment.systemPackages = with pkgs; [
              unstable.btop
              ghosttyTerminfo # infocmp -x xterm-ghostty | ssh YOUR-SERVER -- tic -x -
              pciutils
              usbutils
            ];
          };
      in
      {
        nixos.zsh =
          { pkgs, ... }@args:
          (baseZshConfig args)
          // {
            users.defaultUserShell = pkgs.zsh;
          };

        darwin.zsh = baseZshConfig;

        homeManager.zsh =
          { lib, pkgs, config, ... }:
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
                shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
                  netbird = "netbird-wt0";
                };
                # Lock in the legacy default (home directory). HM 26.05 warns that
                # the default will shift to the XDG config dir when xdg.enable=true.
                dotDir = config.home.homeDirectory;
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
                package =
                  if pkgs.stdenv.hostPlatform.isDarwin then
                    pkgs.direnv.overrideAttrs (_: {
                      doCheck = false;
                    })
                  else
                    pkgs.direnv;
                nix-direnv.enable = true;
              };

              tmux = {
                enable = true;
                clock24 = true;
              };

              fastfetch.enable = true;
              btop = {
                enable = true;
                package = pkgs.unstable.btop;
              };
            };
          };
      };
  };
}
