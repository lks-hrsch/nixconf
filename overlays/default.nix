{ inputs }:
{
  unstable = import ./unstable.nix { inherit (inputs) nixpkgs-unstable; };
  firefox-addons = import ./firefox-addons.nix { inherit inputs; };
  nix4vscode = inputs.nix4vscode.overlays.default;
}
