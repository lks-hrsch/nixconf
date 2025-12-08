{ inputs }:
{
  unstable = import ./unstable.nix { nixpkgs-unstable = inputs.nixpkgs-unstable; };
  firefox-addons = import ./firefox-addons.nix { inherit inputs; };
}
