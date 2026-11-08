{ nixpkgs-unstable }:
_final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
    overlays = [
      # 1Password for Safari (App Store, 8.12.44) migrated the shared vault data past the
      # nixpkgs-unstable app (8.12.42): "Your saved data appears to be newer than this version".
      # Drop once nixpkgs-unstable ships >= 8.12.44: `nix flake update nixpkgs-unstable`, rebuild.
      (_: p: {
        _1password-gui =
          if p.stdenv.hostPlatform.isDarwin && p.lib.versionOlder p._1password-gui.version "8.12.44" then
            p._1password-gui.overrideAttrs {
              version = "8.12.44";
              src = p.fetchurl {
                url = "https://downloads.1password.com/mac/1Password-8.12.44-aarch64.zip";
                hash = "sha256-mySxRkv0N4DwThr6+LB0LyFjypTbiwYgBZ56BaJJj6E=";
              };
            }
          else
            p._1password-gui;
      })
    ];
  };
}
