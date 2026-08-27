{ config, ... }:
{
  flake.modules.nixos.desktop =
    { pkgs, lib, ... }:
    {
      options.desktop.monitors = {
        primary = lib.mkOption {
          type = lib.types.str;
          description = "Primary monitor connector name (e.g. \"DP-3\").";
        };
        secondary = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional secondary monitor connector name (e.g. \"DP-2\").";
        };
      };

      options.desktop.bar = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = ''
          Per-host overrides for noctalia's bar.main settings. Keys are
          noctalia's own, so anything under [bar.main] is reachable. Typos
          are caught by `noctalia config validate` at build time.
        '';
        example = lib.literalExpression ''
          { end = [ "CPU" "ram" "battery" "clock" ]; }
        '';
      };

      config = {
        i18n.inputMethod = {
          enable = true;
          type = "ibus";
          ibus.engines = [ pkgs.ibus-engines.mozc ];
        };

        services.gnome.gnome-keyring.enable = true;

        # Auto-mount removable storage (USB sticks, SD cards) without user
        # action; udisks2 does the mounting, gvfs backs Nautilus, devmon
        # watches udisks2 and triggers the mount.
        services = {
          devmon.enable = true;
          gvfs.enable = true;
          udisks2.enable = true;

          # gvfsd-wsdd talks to a *running* wsdd over /run/wsdd/wsdd.sock
          samba-wsdd = {
            enable = true;
            discovery = true;
          };
        };

        nixpkgs.overlays = [
          config.repo.overlays.firefox-addons
          config.repo.overlays.nix-vscode-extensions
        ];

        nix.settings = {
          substituters = [
            "https://hyprland.cachix.org"
            "https://noctalia.cachix.org"
            "https://cache.nixos-cuda.org"
            "https://cuda-maintainers.cachix.org"
          ];
          trusted-public-keys = [
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          ];
        };

        environment.systemPackages = with pkgs; [
          nautilus # file manager
          pavucontrol # sound

          # some dependencies
          gtk3
          qt5.qtbase
        ];
      };
    };

  flake.modules.homeManager.desktop =
    { lib, pkgs, ... }:
    {
      imports = with config.flake.modules.homeManager; [
        bruno
        ghostty
        firefox
        obsidian
        vscode
        obsstudio
        thunderbird
      ];

      xdg = {
        enable = true;
        userDirs = lib.mkIf pkgs.stdenv.isLinux {
          enable = true;
          createDirectories = true;
          # Keep exporting XDG session variables (legacy HM default; 26.05 default
          # flips to false at stateVersion >= "26.05").
          setSessionVariables = true;
          extraConfig = {
            # Key format changed in HM 26.05: bare name instead of XDG_<NAME>_DIR.
            SCREENSHOTS = "$HOME/Pictures/Screenshots";
          };
        };
      };
    };
}
