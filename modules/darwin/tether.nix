{ config, ... }:
let
  inherit (config.flake.users.owner) username;
in
{
  flake.modules.darwin.tether =
    { pkgs, ... }:
    let
      # No nixpkgs package, no Homebrew cask. Bump version and hash together.
      tether = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "open-webui-tether";
        version = "0.1.16";
        src = pkgs.fetchurl {
          url = "https://github.com/open-webui/tether/releases/download/v${finalAttrs.version}/tether-arm64.dmg";
          hash = "sha256-dVWFBMix+3ozcjXS1IbwY/aFcOhU2bVw3DAiLhhzdvw=";
        };
        nativeBuildInputs = [ pkgs.undmg ];
        sourceRoot = ".";
        dontFixup = true; # keeps the Developer ID signature and notarization valid
        installPhase = ''
          runHook preInstall
          mkdir -p $out/Applications
          cp -R "Open WebUI Tether.app" $out/Applications/
          runHook postInstall
        '';
      });
    in
    {
      # nix-darwin rsyncs this into /Applications/Nix Apps (read-only copy).
      environment.systemPackages = [ tether ];
      home-manager.users.${username}.imports = [ config.flake.modules.homeManager.tether ];
    };

  flake.modules.homeManager.tether =
    { lib, pkgs, ... }:
    let
      id = "5d0a7c1e-3b8f-4e6a-9c21-7f4e2a9b6d10"; # any UUID, must stay fixed
      seed = pkgs.writeText "tether-config.json" (
        builtins.toJSON {
          connections = [
            {
              inherit id;
              name = "Open WebUI (deimos)";
              url = "https://open-webui.deimos.mars.lukashirsch.de";
            }
            {
              id = "7b08e537-28f2-4fe8-bdb6-c61bab8a7a7d";
              name = "Open WebUI (develappers)";
              url = "https://ai.develappers-intranet.de";
            }
          ];
          selected = id;
          # The Nix Apps copy is read-only; updates come from bumping the derivation.
          automaticUpdates = false;
        }
      );
    in
    {
      # Seed once: the app rewrites config.json itself (temp file + rename),
      # so a store symlink would be clobbered. Sign-in stays interactive
      # (credentials live in the Keychain via safeStorage).
      home.activation.tetherConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dir="$HOME/Library/Application Support/Tether/data"
        if [ ! -e "$dir/config.json" ]; then
          run mkdir -p "$dir"
          run install -m 600 ${seed} "$dir/config.json"
        fi
      '';
    };
}
