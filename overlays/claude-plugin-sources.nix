# Shared GitHub source pins for claude-code.nix + opencode.nix. Plain data, not a
# module (import-tree would eval it) — imported with `pkgs` by whichever module needs it.
pkgs: {
  # obra/superpowers — repo root is both the marketplace and the plugin
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "22f0b463e7a5e579904dd6211a520321035526f7"; # v7.0.2
    hash = "sha256-rP5YsyGuPd9YSW/Fj3aukrq1bLuV+nwwQMK4JaZQgkI=";
  };
  # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "7801d061243d7b753bad0e0b3c057cd250b11755"; # v5.3.3
    hash = "sha256-CY0EifTY0UVc6/FPGVJjEfYEf/8QLsINQmoYYKZYh98=";
  };
  # JuliusBrussee/caveman — repo root is both marketplace and plugin. Apache-2.0 since 3.0.0
  # (LICENSE-MIT covers pre-3.0.0 contributions); Caveman Cloud is separate and not in the repo.
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "70f4f34e834893ea9af9f4fc6022266bd56d18b1"; # v4.2.0
    hash = "sha256-hGYcJ7r2O/uEAmAfpox7Owht4LN8Rk2kn1y8BSMWpFk=";
  };
}
