# Workaround: upstream nixpkgs-unstable shipped _1password-gui 8.12.21 with a stale
# aarch64-darwin hash. Patch until nixpkgs merges the corrected derivation.
# TODO: remove once `nix flake update nixpkgs-unstable` brings in a working hash.
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  _1password-gui = prev._1password-gui.overrideAttrs (old: {
    src = prev.fetchurl {
      url = "https://downloads.1password.com/mac/1Password-${old.version}-aarch64.zip";
      hash = "sha256-WrWbGzBK65tVNl9Dc3OnJURiPpfbNLOYUJcVT0ETaAs=";
    };
  });
}
