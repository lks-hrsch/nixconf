{ config, ... }:
{
  flake.modules.nixos.gaming =
    { pkgs, lib, ... }:
    {
      # Host-specific facts consumed by the home-manager half (Lutris global
      # options) via osConfig — same pattern as desktop.monitors.
      options.gaming = {
        gpu = lib.mkOption {
          type = lib.types.str;
          default = "card1";
          description = "DRM card name Lutris renders on (see /dev/dri/).";
        };
        gamePath = lib.mkOption {
          type = lib.types.str;
          default = "/shared/games";
          description = "Lutris default game installation path.";
        };
      };

      config = {
        # Gaming packages track nixpkgs-unstable (pkgs.unstable via
        # overlays/unstable.nix) for the latest patches.
        environment.systemPackages = with pkgs.unstable; [
          mangohud
        ];

        # Co-locate the user half: hosts importing the nixos gaming module get
        # the home-manager gaming module too (requires the homeManager module).
        # `config` here is the flake-parts config, not the NixOS config — the
        # NixOS module's own config must not be referenced in imports.
        home-manager.users.${config.flake.users.owner.username}.imports = [
          config.flake.modules.homeManager.gaming
        ];

        programs = {
          # STEAM
          steam = {
            enable = true;
            package = pkgs.unstable.steam;
            gamescopeSession.enable = true;
            protontricks = {
              enable = true;
              package = pkgs.unstable.protontricks;
            };
            remotePlay.openFirewall = true; # https://github.com/NixOS/nixpkgs/issues/238305
            # Declarative Proton-GE (replaces imperative protonup-ng);
            # shows up in Steam as "GE-Proton".
            extraCompatPackages = [ pkgs.unstable.proton-ge-bin ];
          };

          # enabled by gamescopeSession; pin the package to unstable
          gamescope.package = pkgs.unstable.gamescope;

          # no package option — gamemoded stays on stable nixpkgs
          gamemode = {
            enable = true;
          };
        };
      };
    };

  flake.modules.homeManager.gaming =
    { pkgs, osConfig, ... }:
    {
      programs.lutris = {
        enable = true;
        package = pkgs.unstable.lutris;
        # Reuse the system Steam package (option docs recommend exactly this).
        steamPackage = osConfig.programs.steam.package;
        extraPackages = with pkgs.unstable; [
          umu-launcher # required: lutris >= 0.5.17 launches Proton through umu
          winetricks
          gamemode # reaches the host gamemoded over D-Bus from inside the FHS env
          mangohud
        ];
        # steamcompattool output, symlinked into ~/.local/share/lutris/runners/wine/
        protonPackages = [ pkgs.unstable.proton-ge-bin ];
        # NOTE: never set programs.lutris.runners or defaultWinePackage here:
        # they write to ~/.config/lutris, which flips lutris' CONFIG_DIR away
        # from ~/.local/share/lutris and orphans all existing game configs.
      };

      # Lutris global options (the HM module has no game_path option).
      # dataFile, NOT configFile — see CONFIG_DIR note above. Read-only:
      # Preferences -> Global options is edited here, not in the GUI.
      xdg.dataFile."lutris/system.yml".text = ''
        system:
          game_path: ${osConfig.gaming.gamePath}
          gpu: ${osConfig.gaming.gpu}
      '';
    };
}
