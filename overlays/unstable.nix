{ nixpkgs-unstable }:
_final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
  };
}
