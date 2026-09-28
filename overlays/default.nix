{ inputs }:
{
  unstable = import ./unstable.nix { inherit (inputs) nixpkgs-unstable; };
  firefox-addons = import ./firefox-addons.nix { inherit inputs; };
  nix-vscode-extensions = inputs.nix-vscode-extensions.overlays.default;
}
