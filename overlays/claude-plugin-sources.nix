# Shared GitHub source pins for claude-code.nix + opencode.nix. Plain data, not a
# module (import-tree would eval it) — imported with `pkgs` by whichever module needs it.
pkgs: {
  # obra/superpowers — repo root is both the marketplace and the plugin
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "2ce8aa15d05bd57213e6f746f953aafb7ded7a8b"; # v7.0.1
    hash = "sha256-9+69YEdjdaDu5sWTyAbufSVcZgGD7h6wAq4nUVY2syE=";
  };
  # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "16352ac229eb08a9598dcae48fe9f2b342567d86"; # v5.3.2
    hash = "sha256-IJlhfkdXI6pMZZCZO7XBRg88LBiNfzc5Gnm4ofGybL8=";
  };
  # JuliusBrussee/caveman — repo root is both marketplace and plugin. v2.0.0 added a
  # BSL-1.1 component (self-host free, resale licensed); /caveman itself stays MIT — fine for personal use.
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "d262ab3882952a59312ff3537cd86d894523c5ab"; # v4.0.1
    hash = "sha256-2xZHdWkWJrPAJ8++qW0Xmb3eORZ41e+GsZjIphqTtlI=";
  };
}
