{ nixpkgs-unstable }:
final: prev: {
  unstable = import nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config = prev.config;
  };
}
