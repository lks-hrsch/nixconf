# Shared GitHub source pins for plugins used by both
# modules/home-manager/claude-code/claude-code.nix and modules/home-manager/opencode.nix.
# Plain data, not a module — kept outside modules/ (import-tree would otherwise
# try to evaluate it as one) and imported with `pkgs` from whichever module needs it.
pkgs: {
  # obra/superpowers — repo root is both the marketplace and the plugin
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "3dcbd5c4b48e02263fbf4a3c01e3fe4f81d584d9"; # v6.2.0
    hash = "sha256-F5LEk0yNWbMpan1vZSFZM76XSpsFGvA7h8q6Idrvenk=";
  };
  # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b"; # main as of 2026-07-15 (v4.8.4 + 53)
    hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
  };
  # JuliusBrussee/caveman — repo root is both the marketplace and the plugin
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "fcf7663366c217dc8f334a11028de52ed950ceab"; # v1.10.0
    hash = "sha256-3lPEPb+hzomLLz4xfU7wQS++10gXP0UbXHXq/yluAGM=";
  };
}
