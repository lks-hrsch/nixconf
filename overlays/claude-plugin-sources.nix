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
  # JuliusBrussee/caveman — repo root is both marketplace and plugin. v2.0.0 added a
  # BSL-1.1 component (self-host free, resale licensed); /caveman itself stays MIT — fine for personal use.
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "d262ab3882952a59312ff3537cd86d894523c5ab"; # v4.0.1
    hash = "sha256-2xZHdWkWJrPAJ8++qW0Xmb3eORZ41e+GsZjIphqTtlI=";
  };
}
