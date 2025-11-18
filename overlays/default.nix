{ nixpkgs-unstable }:
{
  unstable = import ./unstable.nix { inherit nixpkgs-unstable; };
}
