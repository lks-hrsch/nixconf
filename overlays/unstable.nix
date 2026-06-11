{ nixpkgs-unstable }:
final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
    overlays = [
      (import ./claude-code.nix)
      (import ./opencode.nix)
      (import ./vscode.nix)
    ];
  };
}
